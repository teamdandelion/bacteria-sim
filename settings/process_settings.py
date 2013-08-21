import json

outDict = {}
with open("settings.csv", "r") as f:
  for line in f.readlines():
    if line[0] == "#": continue
    vals = [v.strip() for v in line.split(",")]
    [DescriptiveName, VariableName, ValueType, DefaultValue, MinValue, MaxValue] = vals
    if ValueType == "Number":
      DefaultValue = float(DefaultValue)
      MinValue = float(MinValue)
      MaxValue = float(MaxValue)
    subDict = {"DescriptiveName": DescriptiveName,  "VariableName": VariableName,
               "ValueType": ValueType,  "DefaultValue": DefaultValue,  "MinValue": MinValue,  "MaxValue": MaxValue}
    outDict[VariableName] = subDict

outStr = json.dumps(outDict,sort_keys=True, indent=2, separators=(',', ': '))
with open("settings.json", "w") as f:
  f.write(outStr)
