import xml.etree.ElementTree as ET
import os
import plistlib

class DataManager:
    def __init__(self, resources_path, hash_path=None):
        self.resources_path = resources_path
        self.hash_path = hash_path
        self.models = self.load_plist('models.plist')
        self.roms = self.load_plist('roms.plist')
        self.machine_cache = {}
        self.software_cache = {}

    def load_plist(self, filename):
        path = os.path.join(self.resources_path, filename)
        if not os.path.exists(path):
            print(f"DEBUG: DataManager failed to find: {path}")
            return None
        with open(path, 'rb') as f:
            return plistlib.load(f)

    def get_machine_description(self, machine_name):
        if machine_name in self.machine_cache:
            return self.machine_cache[machine_name]
        
        desc = self.load_plist(f'{machine_name}.plist')
        if desc:
            self.machine_cache[machine_name] = desc
        return desc

    def get_software_lists(self, machine_name):
        desc = self.get_machine_description(machine_name)
        if not desc or 'software' not in desc:
            return []
        
        results = []
        for item in desc['software']:
            xml_file = None
            filter_val = None
            if isinstance(item, str):
                xml_file = item
            elif isinstance(item, dict):
                xml_file = item.get('name')
                filter_val = item.get('filter')
            elif isinstance(item, list) and len(item) >= 1:
                xml_file = item[0]
                if len(item) >= 2:
                    filter_val = item[1]
            
            if xml_file:
                # Ensure .xml extension
                if not xml_file.endswith(".xml"):
                    xml_file += ".xml"
                
                list_name = xml_file.replace(".xml", "")
                software_items = self.load_software_xml(xml_file)
                
                # We always append to results if the XML exists, 
                # even if items are empty (to show the header at least)
                if xml_file in self.software_cache:
                    filtered_items = software_items
                    if filter_val:
                        # Improved comma-aware filtering
                        filtered_items = []
                        for s in software_items:
                            comp = s.get('compatibility')
                            if not comp:
                                filtered_items.append(s)
                            else:
                                if filter_val in comp.split(','):
                                    filtered_items.append(s)
                    
                    results.append({
                        'name': list_name,
                        'description': self.software_cache[xml_file]['description'],
                        'items': filtered_items
                    })
        return results

    def load_software_xml(self, xml_file):
        if xml_file in self.software_cache:
            return self.software_cache[xml_file]['items']
        
        if not self.hash_path:
            return []
            
        path = os.path.join(self.hash_path, xml_file)
        if not os.path.exists(path):
            return []
            
        try:
            tree = ET.parse(path)
            root = tree.getroot()
            
            list_desc = root.attrib.get('description', xml_file.replace(".xml", ""))
            items = []
            
            for sw in root.findall('software'):
                sw_name = sw.attrib.get('name')
                sw_desc = sw.find('description')
                sw_desc_text = sw_desc.text if sw_desc is not None else sw_name
                
                # Check for compatibility
                compatibility = None
                for sharedfeat in sw.findall('sharedfeat'):
                    if sharedfeat.attrib.get('name') == 'compatibility':
                        compatibility = sharedfeat.attrib.get('value')
                        break
                
                items.append({
                    'name': sw_name,
                    'description': sw_desc_text,
                    'compatibility': compatibility
                })
            
            # Sort items by description
            items.sort(key=lambda x: x['description'].lower())
            
            self.software_cache[xml_file] = {
                'description': list_desc,
                'items': items
            }
            return items
        except Exception as e:
            print(f"Error parsing software XML {xml_file}: {e}")
            return []

    def get_flat_machines(self, models=None):
        if models is None:
            models = self.models
        
        machines = []
        for model in models:
            if 'value' in model and model['value']:
                machines.append({
                    'name': model['value'],
                    'description': model.get('description', model['value'])
                })
            if 'children' in model:
                machines.extend(self.get_flat_machines(model['children']))
        return machines
