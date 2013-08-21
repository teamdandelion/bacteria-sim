import json, os

def parse_gui_settings():
  outDict = {}
  with open("gui_settings.csv", "r") as f:
    for line in f.readlines():
      if line[0] == "#": continue
      vals = [v.strip() for v in line.split(",")]
      [VariableName, DescriptiveName, ValueType, DefaultValue, MinValue, MaxValue] = vals
      if ValueType == "Number":
        DefaultValue = float(DefaultValue)
        MinValue = float(MinValue)
        MaxValue = float(MaxValue)
      subDict = {"descriptiveName": DescriptiveName,  "variableName": VariableName,
                 "valueType": ValueType,  "value": DefaultValue,  "minValue": MinValue,  "maxValue": MaxValue}
      outDict[VariableName] = subDict
  writeToJson(outDict, "gui_settings.json")

def parse_non_gui_settings():
  outDict = {}
  with open("non_gui_settings.csv", "r") as f:
    for line in f.readlines():
      if not line or line[0] == "#" or line[0] == "\n": continue
      vals = [v.strip() for v in line.split(",")]
      [VariableName, Type, Value] = vals
      if Type == "Number":
        Value = float(Value)
      elif Type == "Boolean":
        Value = True if Value == "true" else False
      outDict[VariableName] = Value
  writeToJson(outDict, "non_gui_settings.json")


def writeToJson(dict2Json, file_name):
  outStr = json.dumps(dict2Json, sort_keys=True, indent=2, separators=(',', ': '))
  with open(file_name, "w") as f:
    f.write(outStr)

if __name__ == '__main__':
  os.chdir("settings")
  parse_gui_settings()
  parse_non_gui_settings()
