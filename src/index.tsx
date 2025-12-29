import { Image, ImageRequireSource, processColor } from 'react-native';
import NativeMediaLibrary from './NativeMediaLibrary';

type ImagesTypes = ImageRequireSource | string;

export interface FetchAssetsOptions {
  mediaType?: MediaType[];
  sortBy?: 'creationTime' | 'modificationTime';
  sortOrder?: 'asc' | 'desc';
  extensions?: string[];
  requestUrls?: boolean;
  limit?: number;
  offset?: number;
  onlyFavorites?: boolean;
  collectionId?: string;
}

export interface FetchThumbnailOptions {
  url: string;
  time?: number;
  quality?: number;
}

export interface Thumbnail {
  url: string;
  width: number;
  height: number;
}

interface SaveToLibrary {
  localUrl: string;
  album?: string;
}

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

export interface AssetItem {
  readonly filename: string;
  readonly id: string;
  readonly creationTime?: number;
  readonly modificationTime?: number;
  readonly mediaType: MediaType;
  readonly duration: number;
  readonly width: number;
  readonly height: number;
  readonly uri: string;
  // only on IOS
  readonly subtypes?: MediaSubType[];
}

export interface DiskAssetItem {
  readonly isDirectory: boolean;
  readonly filename: string;
  readonly creationTime: number;
  readonly size: number;
  readonly uri: string;
}

export interface CollectionItem {
  readonly filename: string;
  readonly id: string;
  // On Android it will be approximate count
  readonly count: number;
}

export interface ImageResizeParams {
  uri: ImagesTypes;
  width?: number;
  height?: number;
  format?: 'jpeg' | 'png';
  resultSavePath: string;
}

export interface ImageCropParams {
  uri: ImagesTypes;
  x: number;
  y: number;
  width: number;
  height: number;
  format?: 'jpeg' | 'png';
  resultSavePath: string;
}

interface CombineImage {
  image: ImagesTypes;
  positions?: { x: number; y: number };
}

export interface FullAssetItem extends AssetItem {
  // on android, it will be available only from API 24 (N)
  readonly location?: { latitude: number; longitude: number };
}

const prepareImages = (images: ImagesTypes[]): string[] => {
  return images.map((image) => {
    if (typeof image === 'string') return image;
    return Image.resolveAssetSource(image).uri;
  });
};

const prepareCombineImages = (
  images: CombineImage[]
): { image: string; positions?: { x: number; y: number } }[] => {
  return images.map((item) => {
    if (typeof item.image === 'string') {
      return { image: item.image, positions: item.positions };
    }
    return {
      image: Image.resolveAssetSource(item.image).uri,
      positions: item.positions,
    };
  });
};

const prepareImage = (image: ImagesTypes): string => {
  if (typeof image === 'string') return image;
  return Image.resolveAssetSource(image).uri;
};

export const mediaLibrary = {
  get cacheDir(): string {
    return NativeMediaLibrary.cacheDir().replace(/\/$/, '');
  },

  async getAssets(options?: FetchAssetsOptions): Promise<AssetItem[]> {
    const params = {
      mediaType: options?.mediaType ?? ['photo', 'video'],
      sortBy: options?.sortBy,
      sortOrder: options?.sortOrder,
      limit: options?.limit,
      offset: options?.offset,
      onlyFavorites: options?.onlyFavorites ?? false,
      collectionId: options?.collectionId,
    };
    if (params.offset && !params.limit) {
      throw new Error(
        'limit parameter must be present in order to make a pagination'
      );
    }
    const result = await NativeMediaLibrary.getAssets(params);
    return result as AssetItem[];
  },

  async getFromDisk(options: {
    path: string;
    extensions?: string[];
  }): Promise<DiskAssetItem[]> {
    const result = await NativeMediaLibrary.getFromDisk({
      ...options,
      extensions: options.extensions ? options.extensions.join(',') : undefined,
    });
    return result as DiskAssetItem[];
  },

  async getCollections(): Promise<CollectionItem[]> {
    const result = await NativeMediaLibrary.getCollections();
    return result as CollectionItem[];
  },

  async getAsset(id: string): Promise<FullAssetItem | undefined> {
    const result = await NativeMediaLibrary.getAsset(id);
    return result as FullAssetItem | undefined;
  },

  async exportVideo(params: {
    identifier: string;
    resultSavePath: string;
  }): Promise<FullAssetItem | undefined> {
    const result = await NativeMediaLibrary.exportVideo(params);
    return result as FullAssetItem | undefined;
  },

  async saveToLibrary(params: SaveToLibrary): Promise<AssetItem> {
    const result = await NativeMediaLibrary.saveToLibrary(params);
    const response = result as AssetItem | { error: string };
    if ('error' in response) {
      throw new Error(response.error);
    }
    return response;
  },

  async fetchVideoFrame(
    params: FetchThumbnailOptions
  ): Promise<Thumbnail | undefined> {
    const result = await NativeMediaLibrary.fetchVideoFrame({
      time: params.time ?? 0,
      quality: params.quality ?? 1,
      url: params.url,
    });
    return result as Thumbnail | undefined;
  },

  async combineImages(params: {
    readonly images: (CombineImage | ImagesTypes)[];
    readonly resultSavePath: string;
    readonly mainImageIndex?: number;
    readonly backgroundColor?: ColorValue | undefined;
  }): Promise<{ result: boolean }> {
    const images = params.images.map((img) =>
      typeof img === 'object' && 'image' in img ? img : { image: img }
    );
    const result = await NativeMediaLibrary.combineImages({
      images: prepareCombineImages(images),
      resultSavePath: params.resultSavePath,
      mainImageIndex: params.mainImageIndex ?? 0,
      backgroundColor: params.backgroundColor
        ? processColor(params.backgroundColor)
        : processColor('transparent'),
    });
    return result as { result: boolean };
  },

  async imageResize(params: ImageResizeParams): Promise<{ result: boolean }> {
    const result = await NativeMediaLibrary.imageResize({
      uri: prepareImage(params.uri),
      resultSavePath: params.resultSavePath,
      format: params.format ?? 'png',
      height: params.height ?? -1,
      width: params.width ?? -1,
    });
    return result as { result: boolean };
  },

  async imageCrop(params: ImageCropParams): Promise<{ result: boolean }> {
    const result = await NativeMediaLibrary.imageCrop({
      ...params,
      uri: prepareImage(params.uri),
      format: params.format ?? 'png',
    });
    return result as { result: boolean };
  },

  async imageSizes(params: { images: ImagesTypes[] }): Promise<
    {
      width: number;
      height: number;
      size: number;
    }[]
  > {
    const result = await NativeMediaLibrary.imageSizes({
      images: prepareImages(params.images),
    });
    return result as { width: number; height: number; size: number }[];
  },

  async downloadAsBase64(params: {
    url: string;
  }): Promise<{ base64: string } | undefined> {
    const result = await NativeMediaLibrary.downloadAsBase64(params);
    return result as { base64: string } | undefined;
  },
};
