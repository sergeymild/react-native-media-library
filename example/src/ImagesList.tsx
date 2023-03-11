import React, { useEffect, useState } from 'react';
import { AssetItem, mediaLibrary } from 'react-native-media-library';
import { Dimensions, FlatList } from 'react-native';
import FastImage from 'react-native-fast-image';

const width = Dimensions.get('window').width;
export const ImagesList: React.FC<{ collection: string | undefined }> = (
  props
) => {
  const [images, setImages] = useState<AssetItem[]>([]);

  useEffect(() => {
    mediaLibrary
      .getAssets({
        mediaType: ['video'],
        collectionId: props.collection === '-1' ? undefined : props.collection,
      })
      .then(setImages);

    // mediaLibrary
    //   .imageSizes({
    //     images: [`file:///storage/emulated/0/DCIM/image.png`],
    //   })
    //   .then(console.log);
  }, []);

  // console.log(
  //   '[ImagesList.ImagesList]',
  //   JSON.stringify(
  //     images.map((o) => o.uri),
  //     undefined,
  //     2
  //   )
  // );

  return (
    <FlatList<AssetItem>
      numColumns={3}
      data={images}
      windowSize={1}
      style={{ flex: 1, backgroundColor: 'red' }}
      renderItem={(info) => {
        return (
          <FastImage
            resizeSize={{ width: width / 3, height: width / 3 }}
            width={width / 3}
            height={width / 3}
            source={{
              uri: info.item.uri,
              resizeSize: { width: width / 3, height: width / 3 },
            }}
            style={{
              width: width / 3,
              height: width / 3,
              backgroundColor: 'yellow',
            }}
          />
        );
      }}
    />
  );
};
