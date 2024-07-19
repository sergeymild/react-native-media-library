import {
  Image,
  ImageRequireSource,
  NativeModules,
  Platform,
} from 'react-native';
import { ColorValue } from './StyleSheet';
import { processColor } from 'react-native';
import type { ProcessedColorValue } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-media-library' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const MediaLibrary = NativeModules.MediaLibrary
  ? NativeModules.MediaLibrary
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

MediaLibrary.install();

declare global {
  var __mediaLibrary: {
    getAsset(
      id: string,
      callback: (item: FullAssetItem | undefined) => void
    ): void;
    exportVideo(
      params: {
        identifier: string;
        resultSavePath: string;
      },
      callback: (item: FullAssetItem | undefined) => void
    ): void;
    getAssets(
      options: FetchAssetsOptions,
      callback: (item: AssetItem[]) => void
    ): void;
    getCollections(callback: (items: CollectionItem[]) => void): void;
    saveToLibrary(
      params: SaveToLibrary,
      callback: (item: AssetItem | { error: string }) => void
    ): void;

    fetchVideoFrame(
      params: FetchThumbnailOptions,
      callback: (item: Thumbnail) => void
    ): void;
    combineImages(
      params: {
        images: string[];
        resultSavePath: string;
        readonly mainImageIndex?: number;
        readonly backgroundColor?: ProcessedColorValue | null | undefined;
      },
      callback: (item: { result: boolean }) => void
    ): void;

    imageResize(
      params: ImageResizeParams,
      callback: (item: { result: boolean }) => void
    ): void;
    imageCrop(
      params: ImageCropParams,
      callback: (item: { result: boolean }) => void
    ): void;

    imageSizes(
      params: { images: string[] },
      callback: (
        items: {
          width: number;
          height: number;
          size: number;
        }[]
      ) => void
    ): void;

    downloadAsBase64(
      params: { url: string },
      callback: (data: { base64: string } | undefined) => void
    ): void;

    cacheDir(): string;
  };
}

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

export interface CollectionItem {
  readonly filename: string;
  readonly id: string;
  // On Android it will be approximate count
  readonly count: number;
}

export interface ImageResizeParams {
  uri: ImageRequireSource | string;
  width?: number;
  height?: number;
  format?: 'jpeg' | 'png';
  resultSavePath: string;
}

export interface ImageCropParams {
  uri: ImageRequireSource | string;
  x: number;
  y: number;
  width: number;
  height: number;
  format?: 'jpeg' | 'png';
  resultSavePath: string;
}

export interface FullAssetItem extends AssetItem {
  readonly url: string;
  // on android, it will be available only from API 24 (N)
  readonly location?: { latitude: number; longitude: number };
}

const prepareImages = (images: ImagesTypes[]): string[] => {
  return images.map((image) => {
    if (typeof image === 'string') return image;
    return Image.resolveAssetSource(image).uri;
  });
};

const prepareImage = (image: ImagesTypes): string => {
  if (typeof image === 'string') return image;
  return Image.resolveAssetSource(image).uri;
};

export const mediaLibrary = {
  get cacheDir(): string {
    return __mediaLibrary.cacheDir().replace(/\/$/, '');
  },

  getAssets(options?: FetchAssetsOptions): Promise<AssetItem[]> {
    const params = {
      mediaType: options?.mediaType ?? ['photo', 'video'],
      sortBy: options?.sortBy,
      sortOrder: options?.sortOrder,
      extensions: options?.extensions,
      requestUrls: options?.requestUrls ?? false,
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
    return new Promise<AssetItem[]>((resolve) => {
      __mediaLibrary.getAssets(params, (response) => resolve(response));
    });
  },

  getCollections(): Promise<CollectionItem[]> {
    return new Promise<CollectionItem[]>((resolve) => {
      __mediaLibrary.getCollections((response) => resolve(response));
    });
  },

  getAsset(id: string): Promise<FullAssetItem | undefined> {
    return new Promise<FullAssetItem | undefined>((resolve) => {
      __mediaLibrary.getAsset(id, (response) => resolve(response));
    });
  },

  exportVideo(params: {
    identifier: string;
    resultSavePath: string;
  }): Promise<FullAssetItem | undefined> {
    return new Promise<FullAssetItem | undefined>((resolve) => {
      __mediaLibrary.exportVideo(params, (response) => resolve(response));
    });
  },

  saveToLibrary(params: SaveToLibrary) {
    return new Promise<AssetItem>((resolve, reject) => {
      __mediaLibrary.saveToLibrary(params, (response) => {
        if ('error' in response) {
          reject(response.error);
        } else {
          resolve(response);
        }
      });
    });
  },

  fetchVideoFrame(params: FetchThumbnailOptions) {
    return new Promise<Thumbnail | undefined>((resolve) => {
      __mediaLibrary.fetchVideoFrame(
        {
          time: params.time ?? 0,
          quality: params.quality ?? 1,
          url: params.url,
        },
        (response) => resolve(response)
      );
    });
  },

  combineImages(params: {
    images: (ImageRequireSource | string)[];
    resultSavePath: string;
    readonly mainImageIndex?: number;
    readonly backgroundColor?: ColorValue | undefined;
  }) {
    return new Promise<{ result: boolean }>((resolve) => {
      __mediaLibrary.combineImages(
        {
          images: prepareImages(params.images),
          resultSavePath: params.resultSavePath,
          mainImageIndex: params.mainImageIndex,
          backgroundColor: params.backgroundColor
            ? processColor(params.backgroundColor)
            : processColor('transparent'),
        },
        resolve
      );
    });
  },

  imageResize(params: ImageResizeParams) {
    return new Promise<{ result: boolean }>((resolve) => {
      __mediaLibrary.imageResize(
        {
          uri: prepareImage(params.uri),
          resultSavePath: params.resultSavePath,
          format: params.format ?? 'png',
          height: params.height ?? -1,
          width: params.width ?? -1,
        },
        resolve
      );
    });
  },

  imageCrop(params: ImageCropParams) {
    return new Promise<{ result: boolean }>((resolve) => {
      __mediaLibrary.imageCrop(
        {
          ...params,
          uri: prepareImage(params.uri),
          format: params.format ?? 'png',
        },
        resolve
      );
    });
  },

  imageSizes(params: { images: ImagesTypes[] }): Promise<
    {
      width: number;
      height: number;
      size: number;
    }[]
  > {
    return new Promise((resolve) => {
      __mediaLibrary.imageSizes(
        { images: prepareImages(params.images) },
        resolve
      );
    });
  },

  downloadAsBase64(params: {
    url: string;
  }): Promise<{ base64: string } | undefined> {
    return new Promise((resolve) => {
      __mediaLibrary.downloadAsBase64(params, resolve);
    });
  },
};
