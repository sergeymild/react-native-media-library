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
    getAssetUrl(id: string): string;
    getAssets(options?: {
      mediaType?: string[];
      requestUrls?: boolean;
      limit?: number;
    }): any[];
  };
}

export const mediaLibrary = {
  getAssets(options?: {
    mediaType?: string[];
    requestUrls?: boolean;
    limit?: number;
  }) {
    return __mediaLibrary.getAssets({
      mediaType: options?.mediaType,
      requestUrls: options?.requestUrls ?? false,
      limit: options?.limit,
    });
  },

  getAssetUrl(id: string) {
    return __mediaLibrary.getAssetUrl(id);
  },
};
