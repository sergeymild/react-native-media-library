import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // Sync methods
  cacheDir(): string;

  // Async methods - using Object for complex types (Codegen limitation)
  getAssets(options: Object): Promise<Object[]>;
  getFromDisk(options: Object): Promise<Object[]>;
  getCollections(): Promise<Object[]>;
  getAsset(id: string): Promise<Object | null>;
  exportVideo(params: Object): Promise<Object | null>;
  saveToLibrary(params: Object): Promise<Object>;
  fetchVideoFrame(params: Object): Promise<Object | null>;
  combineImages(params: Object): Promise<Object>;
  imageResize(params: Object): Promise<Object>;
  imageCrop(params: Object): Promise<Object>;
  imageSizes(params: Object): Promise<Object[]>;
  downloadAsBase64(params: Object): Promise<Object | null>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MediaLibrary');
