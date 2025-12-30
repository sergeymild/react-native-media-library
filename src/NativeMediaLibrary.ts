import { TurboModuleRegistry, type TurboModule } from 'react-native';

// Media types
export type MediaType = 'photo' | 'video' | 'audio' | 'unknown';
export type MediaSubType =
  | 'photoPanorama'
  | 'photoHDR'
  | 'photoScreenshot'
  | 'photoLive'
  | 'photoDepthEffect'
  | 'videoStreamed'
  | 'videoHighFrameRate'
  | 'videoTimelapse'
  | 'videoCinematic'
  | 'unknown';

// Input types for native methods
type GetAssetsOptions = {
  mediaType: MediaType[];
  sortBy?: string;
  sortOrder?: string;
  limit?: number;
  offset?: number;
  onlyFavorites: boolean;
  collectionId?: string;
};

type GetFromDiskOptions = {
  path: string;
  extensions?: string;
};

type ExportVideoParams = {
  identifier: string;
  resultSavePath: string;
};

type SaveToLibraryParams = {
  localUrl: string;
  album?: string;
};

type FetchVideoFrameParams = {
  url: string;
  time: number;
  quality: number;
};

type CombineImageItem = {
  image: string;
  positions?: { x: number; y: number };
};

type CombineImagesParams = {
  images: CombineImageItem[];
  resultSavePath: string;
  mainImageIndex: number;
  backgroundColor: number | null;
};

type ImageResizeParams = {
  uri: string;
  width: number;
  height: number;
  format: string;
  resultSavePath: string;
};

type ImageCropParams = {
  uri: string;
  x: number;
  y: number;
  width: number;
  height: number;
  format: string;
  resultSavePath: string;
};

type ImageSizesParams = {
  images: string[];
};

type DownloadAsBase64Params = {
  url: string;
};

// Output types from native methods
export type AssetItem = {
  filename: string;
  id: string;
  creationTime?: number;
  modificationTime?: number;
  mediaType: MediaType;
  duration: number;
  width: number;
  height: number;
  uri: string;
  subtypes?: MediaSubType[];
};

export type DiskAssetItem = {
  isDirectory: boolean;
  filename: string;
  creationTime: number;
  size: number;
  uri: string;
};

export type CollectionItem = {
  filename: string;
  id: string;
  count: number;
};

export type FullAssetItem = AssetItem & {
  location?: { latitude: number; longitude: number };
};

export type Thumbnail = {
  url: string;
  width: number;
  height: number;
};

type ImageSizeResult = {
  width: number;
  height: number;
  size: number;
};

type ResultBoolean = {
  result: boolean;
};

type Base64Result = {
  base64: string;
};

type SaveToLibraryResult = AssetItem | { error: string };

export interface Spec extends TurboModule {
  // Sync methods
  cacheDir(): string;

  // Async methods
  getAssets(options: GetAssetsOptions): Promise<AssetItem[]>;
  getFromDisk(options: GetFromDiskOptions): Promise<DiskAssetItem[]>;
  getCollections(): Promise<CollectionItem[]>;
  getAsset(id: string): Promise<FullAssetItem | null>;
  exportVideo(params: ExportVideoParams): Promise<FullAssetItem | null>;
  saveToLibrary(params: SaveToLibraryParams): Promise<SaveToLibraryResult>;
  fetchVideoFrame(params: FetchVideoFrameParams): Promise<Thumbnail | null>;
  combineImages(params: CombineImagesParams): Promise<ResultBoolean>;
  imageResize(params: ImageResizeParams): Promise<ResultBoolean>;
  imageCrop(params: ImageCropParams): Promise<ResultBoolean>;
  imageSizes(params: ImageSizesParams): Promise<ImageSizeResult[]>;
  downloadAsBase64(
    params: DownloadAsBase64Params
  ): Promise<Base64Result | null>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MediaLibrary');
