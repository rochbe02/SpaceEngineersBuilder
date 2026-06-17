import os
import xml.etree.ElementTree as ET
import json

DATA_PATH = r"B:\SteamLibrary\steamapps\common\SpaceEngineers\Content\Data\CubeBlocks"
LOCALIZATION_PATH = r"B:\SteamLibrary\steamapps\common\SpaceEngineers\Content\Data\Localization\MyTexts.resx"

def load_localization(filepath):
    names = {}
    try:
        tree = ET.parse(filepath)
        root = tree.getroot()
        for data in root.iter("data"):
            name = data.get("name", "")
            value = data.findtext("value", "")
            if name and value:
                names[name] = value
    except Exception as e:
        print(f"Error cargando localización: {e}")
    return names

CATEGORIES = {
    "CubeBlock": "Armor",
    "Thrust": "Thrusters",
    "Gyro": "Gyroscopes",
    "LandingGear": "Landing",
    "Parachute": "Landing",
    "InteriorLight": "Lights",
    "ReflectorLight": "Lights",
    "Searchlight": "Lights",
    "Reactor": "Electricity",
    "BatteryBlock": "Electricity",
    "SolarPanel": "Electricity",
    "WindTurbine": "Electricity",
    "HydrogenEngine": "Electricity",
    "Conveyor": "Conveyors",
    "ConveyorConnector": "Conveyors",
    "ConveyorSorter": "Conveyors",
    "ShipConnector": "Conveyors",
    "Collector": "Conveyors",
    "Assembler": "Production",
    "Refinery": "Production",
    "OxygenGenerator": "Production",
    "OxygenTank": "Production",
    "OxygenFarm": "Production",
    "SurvivalKit": "Production",
    "Cockpit": "Control",
    "RemoteControl": "Control",
    "ButtonPanel": "Control",
    "TimerBlock": "Control",
    "EventControllerBlock": "Control",
    "MyProgrammableBlock": "Control",
    "SensorBlock": "Control",
    "TurretControlBlock": "Control",
    "DefensiveCombatBlock": "Control",
    "OffensiveCombatBlock": "Control",
    "FlightMovementBlock": "Control",
    "BasicMissionBlock": "Control",
    "PathRecorderBlock": "Control",
    "BroadcastController": "Control",
    "SmallGatlingGun": "Weapons",
    "SmallMissileLauncher": "Weapons",
    "SmallMissileLauncherReload": "Weapons",
    "LargeGatlingTurret": "Weapons",
    "LargeMissileTurret": "Weapons",
    "InteriorTurret": "Weapons",
    "Warhead": "Weapons",
    "Decoy": "Weapons",
    "Drill": "Tools",
    "ShipWelder": "Tools",
    "ShipGrinder": "Tools",
    "OreDetector": "Tools",
    "RadioAntenna": "Communications",
    "LaserAntenna": "Communications",
    "Beacon": "Communications",
    "TransponderBlock": "Communications",
    "MotorStator": "Mechanical",
    "MotorRotor": "Mechanical",
    "MotorAdvancedStator": "Mechanical",
    "MotorAdvancedRotor": "Mechanical",
    "PistonBase": "Mechanical",
    "PistonTop": "Mechanical",
    "ExtendedPistonBase": "Mechanical",
    "MergeBlock": "Mechanical",
    "Wheel": "Mechanical",
    "MotorSuspension": "Mechanical",
    "CargoContainer": "Storage",
    "CryoChamber": "Storage",
    "Passage": "Structural",
    "Door": "Structural",
    "AirtightSlideDoor": "Structural",
    "AirtightHangarDoor": "Structural",
}

def get_category(type_id):
    return CATEGORIES.get(type_id, "Miscellaneous")

def parse_sbc_file(filepath, localization):
    blocks = {}
    try:
        tree = ET.parse(filepath)
        root = tree.getroot()
    except ET.ParseError as e:
        print(f"Error parseando {filepath}: {e}")
        return blocks

    for definition in root.iter("Definition"):
        try:
            id_elem = definition.find("Id")
            if id_elem is None:
                continue
            type_id = id_elem.findtext("TypeId", "")
            subtype_id = id_elem.findtext("SubtypeId", "")
            if not subtype_id:
                continue

            # Resolver nombre desde localización
            display_name_key = definition.findtext("DisplayName", subtype_id)
            display_name = localization.get(display_name_key, display_name_key)

            cube_size = definition.findtext("CubeSize", "Large")

            size_elem = definition.find("Size")
            block_size = {"x": 1, "y": 1, "z": 1}
            if size_elem is not None:
                block_size = {
                    "x": int(size_elem.get("x", 1)),
                    "y": int(size_elem.get("y", 1)),
                    "z": int(size_elem.get("z", 1))
                }

            pcu = int(definition.findtext("PCU", 0))

            components = {}
            for comp in definition.iter("Component"):
                subtype = comp.get("Subtype", "")
                count = int(comp.get("Count", 0))
                if subtype and count > 0:
                    components[subtype] = components.get(subtype, 0) + count

            if not components:
                continue

            category = get_category(type_id)

            blocks[subtype_id] = {
                "name": display_name,
                "category": category,
                "size": cube_size,
                "block_size": block_size,
                "pcu": pcu,
                "components": components
            }

        except Exception as e:
            print(f"Error en bloque {subtype_id}: {e}")
            continue

    return blocks

def parse_all():
    print("Cargando localización...")
    localization = load_localization(LOCALIZATION_PATH)
    print(f"  -> {len(localization)} entradas cargadas")

    all_blocks = {}
    sbc_files = [f for f in os.listdir(DATA_PATH) if f.lower().endswith(".sbc")]
    print(f"Encontrados {len(sbc_files)} archivos CubeBlocks")

    for filename in sbc_files:
        filepath = os.path.join(DATA_PATH, filename)
        print(f"Parseando {filename}...")
        blocks = parse_sbc_file(filepath, localization)
        print(f"  -> {len(blocks)} bloques encontrados")
        all_blocks.update(blocks)

    print(f"\nTotal: {len(all_blocks)} bloques")
    return all_blocks

def main():
    blocks = parse_all()
    output_path = os.path.join(os.path.dirname(__file__), "data", "blocks_db.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(blocks, f, indent=2, ensure_ascii=False)
    print(f"\nGuardado en: {output_path}")

if __name__ == "__main__":
    main()