
import subprocess

# from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET

st = subprocess.run(["mame", "apple1", "-listxml"], capture_output=True)

if st.returncode != 0: exit(1)

xml = st.stdout
# print(xml)

dom = ET.fromstring(xml)

machine = dom.find('machine[@name="apple1"]')

ramoptions = [int(x.text) for x in machine.findall('ramoption')]

# display
display = []

x = machine.find('display[@tag="screen"]')
print(x)

if x != None:
	display = [int(x.get("width")), int(x.get("height")) * 2]


print(display)
print(ramoptions)