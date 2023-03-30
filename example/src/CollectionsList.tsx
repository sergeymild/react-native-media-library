import React, { useEffect, useState } from 'react';
import { CollectionItem, mediaLibrary } from 'react-native-media-library';
import {
  Dimensions,
  FlatList,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';

const width = Dimensions.get('window').width;
export const CollectionsList: React.FC<{
  setOpenCollection: (id: string) => void;
}> = (props) => {
  const [images, setImages] = useState<CollectionItem[]>([]);

  useEffect(() => {
    mediaLibrary.getCollections().then(setImages);
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
    <FlatList<CollectionItem>
      numColumns={3}
      data={images}
      ListEmptyComponent={
        <TouchableOpacity onPress={() => props.setOpenCollection('-1')}>
          <Text>Open All</Text>
        </TouchableOpacity>
      }
      style={{ marginTop: 100 }}
      renderItem={(info) => {
        //console.log('[CollectionsList.]', info.item);
        return (
          <TouchableOpacity
            onPress={() => props.setOpenCollection(info.item.id)}
            style={{
              width: width / 3,
              height: width / 3,
              alignItems: 'center',
              justifyContent: 'center',
              borderWidth: 1,
            }}
          >
            <Text style={{ color: 'black' }}>{info.item.filename}</Text>
          </TouchableOpacity>
        );
      }}
    />
  );
};
