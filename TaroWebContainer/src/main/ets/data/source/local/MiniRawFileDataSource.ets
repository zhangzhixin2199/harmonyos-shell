import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import { wbLogger } from '../../../utils/Logger';
import { UpdateConfig } from '../bean/UpdateConfig'
import { LocalVersionInfo } from '../bean/LocalVersionInfo';

const TAG = 'MiniRawFileDataSource'

export const RAW_FILE = 'mps'

export class MiniRawFileDataSource {
  constructor() {
  }

  /**
   *  异步拷贝raw文件到磁盘应用文件目录
   * @param context
   * @returns
   */
  async copyMiniRawToDisk(context: common.Context): Promise<LocalVersionInfo | null> {

    let filesDirPath = this.getDiskPath(context) + "/" + RAW_FILE
    return new Promise((resolve, reject) => {
      // 异步操作部分
      try {
        let localVersionInfo: LocalVersionInfo | null = null
        let miniPath = `${context.filesDir}/update`
        if (fs.accessSync(miniPath)) {
          let filenames = fs.listFileSync(miniPath, { recursion: false, listNum: 0 })
          if (filenames.length > 0) {
            resolve(localVersionInfo)
            return
          }
        }
        let result = this.copyRawFilesToDiskSync(context, RAW_FILE, filesDirPath)
        if (result) {
          let lastMiniVersion = result ? UpdateConfig.getInstance().getInitialVersion() : '';
          let path = result ? `${miniPath}/${lastMiniVersion}` : '';
          localVersionInfo = new LocalVersionInfo(lastMiniVersion, path)
        }
        resolve(localVersionInfo)
      } catch (err) {
        reject(err); // 如果操作失败，调用reject并传递错误消息
      }
    })
  }

  /**
   * 获取缓存空间目录
   * @param context
   * @returns
   */
  getDiskPath(context: common.Context): string {
    let path = `${context.filesDir}/update/0`
    return path;
  }

  mkFilesDir(filePath:string){
    try {
      if (!fs.accessSync(filePath)) {
        fs.mkdirSync(filePath,true)
      }
    }catch (e){
      wbLogger.error(TAG, `mkFilesDir failed:`, e);
    }
  }
  /**
   * 断言文件是否可访问
   * @param filePath
   * @returns
   */
  accessSyncMiniFile(filePath: string): Boolean {
    if (!fs.accessSync(filePath)) {
      return true
    }
    return false;
  }

  /**
   * 递归读取Raw文件目录，并拷贝文件
   * @param context
   * @param src
   * @param dest
   * @returns
   */
  copyRawFilesToDiskSync(context: common.Context, src: string, dest: string): boolean {
    wbLogger.debug(TAG, `Directory copy start from %{public}s to %{public}s`, src, dest);
    let entries: Array<string> | null
    try {
      // 目前没有直接判断是rawFile文件目录下的文件类型：目录还是文件，暂时依靠try catch
      // 若是目录不崩溃，若是文件则会报异常
      entries = context.resourceManager.getRawFileListSync(src);
      // 创建目标目录
      this.mkFilesDir(dest)
    } catch (error) {
      entries = null
      wbLogger.error(TAG, `Error copying directory: ${src} to ${dest}`, error);
    }
    wbLogger.debug(TAG, `Directory copy start from %{public}s to %{public}s,length = %{public}s`, src, dest, `${entries?.length}`);
    if (entries != null && entries?.length >= 1) {
      for (const entry of entries) {
        // 拼接完整的源路径和目标路径
        let srcPath = src + "/" + entry;
        let destPath = dest + "/" + entry;
        // 新文件目录，递归调用函数自身
        this.copyRawFilesToDiskSync(context, srcPath, destPath);
      }
    } else {
      // 如果是文件，直接复制到目标路径
      return this.copyRawFileToDiskSync(context, src, dest)
    }
    return true
  }

  /**
   * 拷贝文件
   * @param context
   * @param src
   * @param dest
   * @returns
   */
  copyRawFileToDiskSync(context: common.Context, src: string, dest: string): boolean {
    wbLogger.debug(TAG, `Directory copying from %{public}s to %{public}s`, src, dest);
    try {
      let content = context.resourceManager.getRawFileContentSync(src);
      let file = fs.openSync(dest, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, content.buffer)
      wbLogger.debug(TAG, `Directory copied success from %{public}s to %{public}s`, src, dest);
      return true
    } catch (err) {
      wbLogger.error(TAG, " Directory copying failed" + src + " to " + dest + " with error message: " + err.message + ", error code: " + err.code);
      // } finally {
      //   if (file != undefined) {
      //     fs.closeSync(file);
      //   }
      return true
    }

  }
}