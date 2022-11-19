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
    getAsset(id: string): FullAssetItem;
    getAssets(options?: Options | string): AssetItem[];
    saveToLibrary(localUrl: string): AssetItem | string;
  };
}

interface Options {
  mediaType?: MediaType[];
  sortBy?: 'creationTime' | 'modificationTime';
  sortOrder?: 'asc' | 'desc';
  extensions?: string[];
  requestUrls?: boolean;
  limit?: number;
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
  readonly url?: string;
}

export interface FullAssetItem extends AssetItem {
  readonly url: string;
}

export const mediaLibrary = {
  getAssets(options?: Options): AssetItem[] {
    const params = {
      mediaType: options?.mediaType,
      sortBy: options?.sortBy,
      sortOrder: options?.sortOrder,
      extensions: options?.extensions,
      requestUrls: options?.requestUrls ?? false,
      limit: options?.limit,
    };
    return __mediaLibrary.getAssets(
      Platform.OS === 'android' ? JSON.stringify(params) : params
    );
  },

  getAsset(id: string): FullAssetItem {
    return __mediaLibrary.getAsset(id);
  },

  saveToLibrary(localUrl: string): AssetItem | string {
    return __mediaLibrary.saveToLibrary(localUrl);
  },
};
