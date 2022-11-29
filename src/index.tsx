import { NativeModules, Platform } from 'react-native';

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
    getAssets(
      options: FetchAssetsOptions,
      callback: (item: AssetItem[]) => void
    ): void;
    saveToLibrary(
      params: SaveToLibrary,
      callback: (item: AssetItem) => void
    ): void;
  };
}

export interface FetchAssetsOptions {
  mediaType?: MediaType[];
  sortBy?: 'creationTime' | 'modificationTime';
  sortOrder?: 'asc' | 'desc';
  extensions?: string[];
  requestUrls?: boolean;
  limit?: number;
  offset?: number;
}

interface SaveToLibrary {
  localUrl: string;
  album?: string;
}

export type MediaType = 'photo' | 'video' | 'audio' | 'unknown';
export interface AssetItem {
  readonly filename: string;
  readonly id: string;
  readonly creationTime: number;
  readonly modificationTime: number;
  readonly mediaType: MediaType;
  readonly duration: number;
  readonly width: number;
  readonly height: number;
  readonly uri: string;
  readonly location?: { latitude: number; longitude: number };
}

export interface FullAssetItem extends AssetItem {
  readonly url: string;
}

export const mediaLibrary = {
  getAssets(options?: FetchAssetsOptions): Promise<AssetItem[]> {
    const params = {
      mediaType: options?.mediaType,
      sortBy: options?.sortBy,
      sortOrder: options?.sortOrder,
      extensions: options?.extensions,
      requestUrls: options?.requestUrls ?? false,
      limit: options?.limit,
      offset: options?.offset,
    };
    return new Promise<AssetItem[]>((resolve) => {
      __mediaLibrary.getAssets(params, (response) => resolve(response));
    });
  },

  getAsset(id: string): Promise<FullAssetItem | undefined> {
    return new Promise<FullAssetItem | undefined>((resolve) => {
      __mediaLibrary.getAsset(id, (response) => resolve(response));
    });
  },

  saveToLibrary(params: SaveToLibrary) {
    return new Promise<AssetItem>((resolve) => {
      __mediaLibrary.saveToLibrary(params, (response) => resolve(response));
    });
  },
};
