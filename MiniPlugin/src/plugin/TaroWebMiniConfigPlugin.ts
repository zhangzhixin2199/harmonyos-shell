import { hvigor, HvigorNode, HvigorPlugin,parseJsonFile,Json5Reader} from '@ohos/hvigor';
import { hapTasks, OhosHapContext, OhosPluginId,Target} from '@ohos/hvigor-ohos-plugin';
import { transformSync } from '@babel/core';
import * as fs from 'fs'

export function TaroWebMiniConfigPlugin(): HvigorPlugin {
  return {
    pluginId: 'taroweb-mini-config-plugin',
    context() {
      return {
        data: 'TaroWebMiniConfigPlugin'
      };
    },
    async apply(currentNode: HvigorNode): Promise<void> {
      hvigor.nodesEvaluated(async () => {
        // 注册模块级任务
        setMiniConfigTask(currentNode);
      });
    }
  };
}
function setMiniConfigTask(currentNode: HvigorNode) {
  console.log('TaroWebMiniConfigPlugin setMiniConfigTask start');
  const hapContext = currentNode.getContext(OhosPluginId.OHOS_HAP_PLUGIN) as OhosHapContext;
  const nodepath = hapContext?.getModulePath()
  hapContext?.targets((target: Target) => {
    const targetName = target?.getTargetName()
    const outputPath = target.getBuildTargetOutputPath();
    currentNode.registerTask({
      name: `${targetName}@SetMiniConfig`,
      run(taskContext: HvigorTaskContext) {
        const path = require('path');
        let appFilePath = path.join(nodepath, "mini-config.json5")
        if (!fs.existsSync(appFilePath)) {
          console.warn('mini-config.json5 does not exist,Please set the configuration file');
          return
        }
        let json=''
        try{
          json = Json5Reader.getJson5Obj(appFilePath,'utf8')
        }catch(error){
          console.error('mini-config.json5 is incorrectly formatted')
          console.error(error);
        }
        console.log(json);
        if (json =='') {
          console.warn('mini-config.json5 this file are empty,Please set the configuration');
          return
        }
        const jsonContent = JSON.stringify(json)
        let replacePath = outputPath.replace('default/outputs', 'default/intermediates/res');
        let outputFilePath = path.join(replacePath, "resources", "rawfile", "mini-config.json")
        fs.writeFileSync(outputFilePath, jsonContent)
      },
      dependencies: [`${targetName}@CompileResource`],
      postDependencies: ['assembleHap']
    });
  });
}
export default {
  system: hapTasks,
  plugins:[TaroWebMiniConfigPlugin()]
};