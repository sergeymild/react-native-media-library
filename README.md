# react-native-media-library
React Native JSI access to user's media library


### Configure for iOS
Add NSPhotoLibraryUsageDescription, and NSPhotoLibraryAddUsageDescription keys to your Info.plist:

### Install
add this to `package.json`
```
"react-native-media-library":"sergeymild/react-native-media-library#0.71.2"
```

```ts
<key>NSPhotoLibraryUsageDescription</key>
<string>Give $(PRODUCT_NAME) permission to access your photos</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Give $(PRODUCT_NAME) permission to save photos</string>
```

### Configure for Android
This package automatically adds the `READ_EXTERNAL_STORAGE` and `WRITE_EXTERNAL_STORAGE` permissions. They are used when accessing the user's images or videos.

```ts
<!-- Added permissions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Installation

```sh
add this line to `package.json`
"react-native-media-library": "sergeymild/react-native-media-library#0.71.0"
yarn
npx pod-install
```

## Usage

```js
import { mediaLibrary } from "react-native-media-library";

// ...

export interface CollectionItem {
  readonly filename: string;
  readonly id: string;
}

interface Options {
  mediaType?: MediaType[];
  sortBy?: 'creationTime' | 'modificationTime';
  sortOrder?: 'asc' | 'desc';
  extensions?: string[];
  requestUrls?: boolean;
  limit?: number;
  offset?: number;
  collectionId?: string;
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
}

export interface FullAssetItem extends AssetItem {
  readonly url: string;
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

export interface ImageResizeParams {
  uri: ImageRequireSource | string;
  width?: number;
  height?: number;
  format?: 'jpeg' | 'png';
  resultSavePath: string;
}

mediaLibrary.getCollections(): Promise<CollectionItem[]>
mediaLibrary.getAssets(options?: Options): Promise<AssetItem[]>
mediaLibrary.getAsset(id: string): Promise<FullAssetItem | undefined>
// will return save asset or error string
mediaLibrary.saveToLibrary(params: SaveToLibrary): Promise<FullAssetItem | string>
// returns cache directory
mediaLibrary.cacheDir: string

// retrieve frame from video with passed params
mediaLibrary.fetchVideoFrame(params: FetchThumbnailOptions): Promise<Thumbnail | undefined>

// combine passed images in one
mediaLibrary.combineImages(params: {
  images: (ImageRequireSource | string)[];
  resultSavePath: string;
}): Promise<{ result: boolean }>

// resize image based on passed width and height
mediaLibrary.imageResize(params: ImageResizeParams): Promise<{ result: boolean }>

// resolve passed images sizes
mediaLibrary.imageSizes(params: {
  images: (ImageRequireSource | string)[];
}): Promise<{ result: { width: number; height: number; size: number }[] }>
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
