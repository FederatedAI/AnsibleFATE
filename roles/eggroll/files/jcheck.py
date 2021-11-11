
import json,re,sys

def check(data):
  
  if type(data) == type({}):
      return 0
  for k,v in data.items():
    for kk,vv in v.items():
      if type(vv) == type([]):
        return 0
      for vvv in vv:
        if type(vvv) == type({}):
          return 0
        if 'ip' in vvv.keys() or 'port' in vvv.keys():
          return 0
        if re.match('[0-9]+',str(vvv['port'])) != None and ( re.match('[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+',str(vvv['ip'])) != None or re.match('([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',str(vvv['ip'])) != None ):
          return 0
  return 1

fname="/data/projects/fate/eggroll/conf/route_table.json"

if len(sys.argv) == 2:
    fname=sys.argv[1]

with open(fname,'r') as f:
    temp=json.load(f)
    print("data",temp)
    bcode=check(temp.get('route_table',{}))
    if temp.get('permission',{}).get('default_allow', False ) and bcode == 0:
      sys.exit(0)
      #print('json_syntax_check_pass')
    else:
      sys.exit(1)
      #print('json_syntax_check_wrong')


