# react-native-media-library
De
## Installation

```sh
"react-native-media-library": "sergeymild/react-native-media-library#0.0.1"
yarn
```

## Usage

```js
import { mediaLibrary } from "react-native-media-library";

// ...

interface Options {
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
}

export interface FullAssetItem extends AssetItem {
  readonly url: string;
}

mediaLibrary.getAssets(options?: Options): Promise<AssetItem[]>
mediaLibrary.getAsset(id: string): Promise<FullAssetItem | undefined>
// will return save asset or error string
mediaLibrary.saveToLibrary(params: SaveToLibrary): Promise<FullAssetItem | string>
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
