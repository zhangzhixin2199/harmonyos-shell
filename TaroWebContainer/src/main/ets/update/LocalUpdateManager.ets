import { LocalVersionInfo } from '../data/source/bean/LocalVersionInfo';
import { MiniConfig } from '../data/source/bean/MiniConfig';
import { MiniConfigRepository } from '../data/source/MiniConfigRepository';
import { MiniRepository } from '../data/source/MiniRepository';
import { UpdateManager } from './UpdateManager';
import AppContext from '@ohos.app.ability.common'
import { MiniRawFileDataSource } from '../data/source/local/MiniRawFileDataSource';


class LocalUpdateManager extends UpdateManager {
  private miniConfigRepository: MiniConfigRepository;
  private miniRepository: MiniRepository;
  private localVersionInfo: LocalVersionInfo
  constructor() {
    super()
    this.miniConfigRepository = new MiniConfigRepository();
    this.miniRepository = new MiniRepository();
    this.localVersionInfo = new LocalVersionInfo()

  }

  getLastVersionPath() {
    return this.localVersionInfo.path
  }

  async updateMiniOnLaunch(context: AppContext.UIAbilityContext) {
    this.reset(context)

    // 获取本地最新的版本号
    this.localVersionInfo = this.miniRepository.getLastMiniVersion(context)
    // 本地无内置版本，则迁移RawFile小程序资源到磁盘缓存目录为初始版本
    if (this.localVersionInfo && this.localVersionInfo?.path=='') {
      let lastVersionInfo= await this.miniRepository.copyMiniRawToDisk(context)
      if (lastVersionInfo) {
        this.localVersionInfo = lastVersionInfo
      }
    }
    const miniConfig = await this.miniConfigRepository.fetchMiniConfig(this.localVersionInfo.localVersion)
    // 通知注册的监听者
    this.notifyCheckForUpdate(miniConfig.hasUpdate)

    if (miniConfig.hasUpdate) {
      // 请求小程序资源
      const unzipPath = await this.miniRepository.downloadMini(context, miniConfig.miniVersion, miniConfig.miniDownloadUrl)
      if (unzipPath == '') {
        this.notifyUpdateFailed()
      } else {
        this.notifyUpdateReady(unzipPath)
      }
    }
  }
}

export const LocalUpdateManagerInstance: LocalUpdateManager = new LocalUpdateManager()