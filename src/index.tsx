import {
  Image,
  type ImageRequireSource,
  processColor,
  type ColorValue,
} from 'react-native';
import NativeMediaLibrary, {
  type MediaType,
  type MediaSubType,
  type AssetItem,
  type DiskAssetItem,
  type CollectionItem,
  type FullAssetItem,
  type Thumbnail,
} from './NativeMediaLibrary';

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

interface SaveToLibrary {
  localUrl: string;
  album?: string;
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

// Re-export types from NativeMediaLibrary
export type {
  MediaType,
  MediaSubType,
  AssetItem,
  DiskAssetItem,
  CollectionItem,
  FullAssetItem,
  Thumbnail,
};

const prepareImages = (images: ImagesTypes[]): string[] => {
  return images.map((image) => {
    if (typeof image === 'string') return image;
    return Image.resolveAssetSource(image)?.uri ?? '';
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
      image: Image.resolveAssetSource(item.image)?.uri ?? '',
      positions: item.positions,
    };
  });
};

const prepareImage = (image: ImagesTypes): string => {
  if (typeof image === 'string') return image;
  return Image.resolveAssetSource(image)?.uri ?? '';
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
    return NativeMediaLibrary.getAssets(params);
  },

  async getFromDisk(options: {
    path: string;
    extensions?: string[];
  }): Promise<DiskAssetItem[]> {
    return NativeMediaLibrary.getFromDisk({
      ...options,
      extensions: options.extensions ? options.extensions.join(',') : undefined,
    });
  },

  async getCollections(): Promise<CollectionItem[]> {
    return NativeMediaLibrary.getCollections();
  },

  async getAsset(id: string): Promise<FullAssetItem | undefined> {
    const result = await NativeMediaLibrary.getAsset(id);
    return result ?? undefined;
  },

  async exportVideo(params: {
    identifier: string;
    resultSavePath: string;
  }): Promise<FullAssetItem | undefined> {
    const result = await NativeMediaLibrary.exportVideo(params);
    return result ?? undefined;
  },

  async saveToLibrary(params: SaveToLibrary): Promise<AssetItem> {
    const result = await NativeMediaLibrary.saveToLibrary(params);
    if ('error' in result) {
      throw new Error(result.error);
    }
    return result;
  },

  async fetchVideoFrame(params: FetchThumbnailOptions) {
    const result = await NativeMediaLibrary.fetchVideoFrame({
      time: params.time ?? 0,
      quality: params.quality ?? 1,
      url: params.url,
    });
    return result ?? undefined;
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
    return NativeMediaLibrary.combineImages({
      images: prepareCombineImages(images),
      resultSavePath: params.resultSavePath,
      mainImageIndex: params.mainImageIndex ?? 0,
      backgroundColor: params.backgroundColor
        ? (processColor(params.backgroundColor) as number)
        : (processColor('transparent') as number),
    });
  },

  async imageResize(params: ImageResizeParams): Promise<{ result: boolean }> {
    return NativeMediaLibrary.imageResize({
      uri: prepareImage(params.uri),
      resultSavePath: params.resultSavePath,
      format: params.format ?? 'png',
      height: params.height ?? -1,
      width: params.width ?? -1,
    });
  },

  async imageCrop(params: ImageCropParams): Promise<{ result: boolean }> {
    return NativeMediaLibrary.imageCrop({
      ...params,
      uri: prepareImage(params.uri),
      format: params.format ?? 'png',
    });
  },

  async imageSizes(params: { images: ImagesTypes[] }): Promise<
    {
      width: number;
      height: number;
      size: number;
    }[]
  > {
    return NativeMediaLibrary.imageSizes({
      images: prepareImages(params.images),
    });
  },

  async downloadAsBase64(params: {
    url: string;
  }): Promise<{ base64: string } | undefined> {
    const result = await NativeMediaLibrary.downloadAsBase64(params);
    return result ?? undefined;
  },
};
