import subprocess
import os
import re

class MameLauncher:
    def __init__(self):
        self.mame_path = "mame"
        self.working_dir = "."
        self.valid_slots_cache = {}

    def get_valid_slots(self, machine):
        if machine in self.valid_slots_cache:
            return self.valid_slots_cache[machine]
        
        if not os.path.exists(self.mame_path) and self.mame_path != "mame":
             return None

        try:
            cmd = [self.mame_path, machine, "-listslots"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            
            slots = set()
            lines = result.stdout.splitlines()
            # MAME -listslots has a header: "SYSTEM      SLOT NAME   SLOT OPTIONS"
            # We want the second column.
            for line in lines:
                line = line.strip()
                if not line or line.startswith("---") or "SLOT NAME" in line:
                    continue
                
                parts = line.split()
                # If the line starts with the machine name, the slot name is in index 1.
                # If it's a sub-slot (starting with whitespace, now stripped), it's in index 0.
                if line.startswith(machine) and len(parts) >= 2:
                    slots.add(parts[1])
                elif len(parts) >= 1:
                    slots.add(parts[0])
            
            self.valid_slots_cache[machine] = slots
            return slots
        except Exception as e:
            print(f"Error getting slots for {machine}: {e}")
            return None

    def get_valid_media(self, machine):
        cache_key = f"{machine}_media"
        if cache_key in self.valid_slots_cache:
            return self.valid_slots_cache[cache_key]
            
        if not os.path.exists(self.mame_path) and self.mame_path != "mame":
             return None

        try:
            cmd = [self.mame_path, machine, "-listmedia"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            
            media_types = set()
            lines = result.stdout.splitlines()
            # Extract common brief names like flop1, cass, etc inside brackets
            for line in lines:
                if "(" in line and ")" in line:
                    match = re.search(r'\((\w+)\)', line)
                    if match:
                        media_types.add(match.group(1))
            
            self.valid_slots_cache[cache_key] = media_types
            return media_types
        except Exception:
            return None

    def build_args(self, machine, slots=None, media=None, soft_list_args=None, extra_options=None):
        args = [machine]
        
        if soft_list_args:
            for sl in soft_list_args:
                args.append(sl)

        args.append("-skip_gameinfo")
        
        
        if slots:
            for slot_name, option in slots.items():
                if option and not slot_name.startswith(':'):
                    # Pass the slot argument regardless of base machine validation
                    args.extend([f"-{slot_name}", option])
        
        if media:
            for media_type, path in media.items():
                if path and not media_type.startswith(':'):
                    # Pass the media argument regardless of base machine validation
                    args.extend([f"-{media_type}", path])
                    
        if extra_options:
            for opt in extra_options:
                args.append(opt)
                
        return args

    def launch(self, machine, slots=None, media=None, soft_list_args=None, extra_options=None, alt_exe=None):
        args = self.build_args(machine, slots, media, soft_list_args, extra_options)
        exe = alt_exe if alt_exe else self.mame_path
        full_cmd = [exe] + args
        print(f"Launching: {subprocess.list2cmdline(full_cmd)}")
        try:
            return subprocess.Popen(full_cmd, cwd=self.working_dir)
        except Exception as e:
            print(f"Error launching MAME: {e}")
            return None
