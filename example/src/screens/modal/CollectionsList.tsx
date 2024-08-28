import React, { useEffect, useState } from 'react';
import { CollectionItem, mediaLibrary } from 'react-native-media-library2';
import { Dimensions, FlatList, Text, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';

const width = Dimensions.get('window').width;
export const CollectionsList: React.FC = () => {
  const navigation = useNavigation();
  const [images, setImages] = useState<CollectionItem[]>([]);

  useEffect(() => {
    mediaLibrary.getCollections().then(setImages);
  }, []);

  return (
    <FlatList<CollectionItem>
      numColumns={3}
      data={images}
      renderItem={(info) => {
        return (
          <TouchableOpacity
            // onPress={() => props.setOpenCollection(info.item.id)}
            onPress={() => {
              //@ts-ignore
              navigation.navigate('ImagesList', { collectionId: info.item.id });
            }}
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
