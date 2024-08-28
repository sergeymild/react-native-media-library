import React, { useEffect, useRef, useState } from 'react';
import {
  AssetItem,
  FetchAssetsOptions,
  mediaLibrary,
} from 'react-native-media-library2';
import {
  Dimensions,
  FlatList,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import FastImage from 'react-native-fast-image';
import { useRoute } from '@react-navigation/native';

const width = Dimensions.get('window').width;
export const ImagesList: React.FC<{ collection: string | undefined }> = (
  props
) => {
  const { params } = useRoute<any>();
  const [images, setImages] = useState<AssetItem[]>([]);
  const options = useRef<FetchAssetsOptions>({
    collectionId: params?.collectionId,
    limit: 50,
    sortBy: 'creationTime',
    sortOrder: 'desc',
  });

  useEffect(() => {
    const strat = Date.now();
    console.log('[ImagesList.]', options.current);
    mediaLibrary.getAssets(options.current).then((r) => {
      console.log(
        '[ImagesList.initial]',
        (Date.now() - strat) / 1000,
        r.length
      );
      setImages(r);
    });
  }, []);

  const mediaType = options.current!.mediaType ?? [];
  const sortBy = options.current!.sortBy;
  let title = 'both';
  if (mediaType.length === 2) title = 'photo';
  if (mediaType.length === 1 && mediaType.includes('video')) title = 'both';
  if (mediaType.length === 1 && mediaType.includes('photo')) title = 'video';

  return (
    <View style={{ flex: 1 }}>
      <View style={{ flexDirection: 'row' }}>
        <TouchableOpacity
          style={{ marginEnd: 8 }}
          onPress={() => {
            options.current!.sortBy =
              sortBy === 'creationTime' ? 'modificationTime' : 'creationTime';
            mediaLibrary.getAssets(options.current).then(setImages);
          }}
        >
          <Text
            children={
              sortBy === 'creationTime' ? 'modificationTime' : 'creationTime'
            }
          />
        </TouchableOpacity>
        <TouchableOpacity
          style={{ marginEnd: 8 }}
          onPress={() => {
            options.current!.sortBy = 'creationTime';
            options.current!.sortOrder =
              options.current!.sortOrder === 'desc' ? 'asc' : 'desc';
            mediaLibrary.getAssets(options.current).then(setImages);
          }}
        >
          <Text
            children={options.current!.sortOrder === 'asc' ? 'desc' : 'asc'}
          />
        </TouchableOpacity>
        <TouchableOpacity
          onPress={() => {
            options.current!.mediaType =
              title === 'both'
                ? ['photo', 'video']
                : title === 'video'
                  ? ['video']
                  : ['photo'];
            mediaLibrary.getAssets(options.current).then(setImages);
          }}
        >
          <Text children={title} />
        </TouchableOpacity>
      </View>
      <FlatList<AssetItem>
        numColumns={3}
        data={images}
        initialNumToRender={50}
        getItemLayout={(_, index) => ({
          length: width / 3,
          offset: (width / 3) * index,
          index,
        })}
        onEndReached={() => {
          const strat = Date.now();
          console.log('[ImagesList.onEndReached]');
          mediaLibrary
            .getAssets({
              ...options.current,
              limit: 50,
              offset: images.length - 1,
            })
            .then((r) => {
              console.log(
                '[ImagesList.more]',
                (Date.now() - strat) / 1000,
                r.length
              );
              setImages([...images, ...r]);
            });
        }}
        renderItem={(info) => {
          return (
            <TouchableOpacity
              onPress={async () => {
                const d = await mediaLibrary.getAsset(info.item.id);
                console.log('[ImagesList.]', JSON.stringify(d, undefined, 2));
              }}
            >
              <FastImage
                resizeSize={{ width: width / 3, height: width / 3 }}
                width={width / 3}
                height={width / 3}
                source={{
                  uri: info.item.uri,
                  //@ts-ignore
                  resizeSize: { width: width / 3, height: width / 3 },
                }}
                style={{
                  width: width / 3,
                  height: width / 3,
                  backgroundColor: 'yellow',
                }}
              />
            </TouchableOpacity>
          );
        }}
      />
    </View>
  );
};
