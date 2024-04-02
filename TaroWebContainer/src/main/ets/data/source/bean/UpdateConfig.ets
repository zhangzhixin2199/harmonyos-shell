import versionCompare from '../bean/CompareVersion'
import { LocalVersionInfo } from './LocalVersionInfo'
import { LightWeightMap } from '@kit.ArkTS'

export class UpdateConfig {
  private static instance: UpdateConfig
  private urlFunc = (version: string) => {
    return ''
  }
  private initialVersion: string = '0'
  private compareVersionFunc: (a: string, b: string) => boolean = versionCompare
  private miniInfos:LightWeightMap<string,LocalVersionInfo> = new LightWeightMap<string,LocalVersionInfo>()
  private constructor() {
  }

  public static getInstance(): UpdateConfig {
    if (!UpdateConfig.instance) {
      UpdateConfig.instance = new UpdateConfig();
    }
    return UpdateConfig.instance;
  }

  getInitialVersion(): string {
    return this.initialVersion
  }

  getUrl(version: string): string {
    return this.urlFunc(version)
  }

  getCompareVersionFunc(): (a: string, b: string) => boolean {
    return this.compareVersionFunc
  }

  setup(initialVersion: string, getUrlFunc: (version: string) => string, compareVersionFunc = versionCompare): void {
    this.urlFunc = getUrlFunc
    this.initialVersion = initialVersion
    this.compareVersionFunc = compareVersionFunc
  }

  setOrReplaceMiniInfo(name:string,versionInfo:LocalVersionInfo){
    if (name&&versionInfo) {
        this.miniInfos.set(name,versionInfo)
    }
  }

  getMiniInfo(name:string): LocalVersionInfo | null{
    return this.miniInfos.get(name)
  }

  getMiniInfos(){
    return this.miniInfos
  }

}