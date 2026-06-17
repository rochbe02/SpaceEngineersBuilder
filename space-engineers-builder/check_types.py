import os
import xml.etree.ElementTree as ET

DATA_PATH = r"B:\SteamLibrary\steamapps\common\SpaceEngineers\Content\Data\CubeBlocks"

type_ids = set()

for filename in os.listdir(DATA_PATH):
    if filename.endswith(".sbc"):
        try:
            tree = ET.parse(os.path.join(DATA_PATH, filename))
            root = tree.getroot()
            for id_elem in root.iter("Id"):
                type_id = id_elem.findtext("TypeId", "")
                if type_id:
                    type_ids.add(type_id)
        except:
            pass

for t in sorted(type_ids):
    print(t)