import * as React from 'react';

import { StyleSheet, View, Text, TouchableOpacity, Image } from 'react-native';
import { mediaLibrary } from 'react-native-media-library';
import { useState } from 'react';
import FastImage from 'react-native-fast-image';

export default function App() {
  const [image, setImage] = useState();

  console.log('[App.App]', image);

  return (
    <View style={styles.container}>
      <TouchableOpacity
        style={{ height: 50 }}
        onPress={() => {
          const start = Date.now();
          // console.log(
          //   '[App.save]',
          //   mediaLibrary.saveToLibrary(
          //     `/data/user/0/com.example.reactnativemedialibrary/files/2222.jpg`
          //   )
          // );
          const assets = mediaLibrary.getAssets({
            requestUrls: false,
            limit: 1,
            mediaType: ['photo'],
            extensions: ['jpg'],
            sortBy: 'creationTime',
            sortOrder: 'asc',
          });
          console.log(
            '[App.]',
            assets.map((e) => e.creationTime)
          );
          // const end = start - Date.now();
          // // console.log('[App.]', JSON.stringify(assets, undefined, 2));
          // console.log(
          //   '[App.]',
          //   assets.length,
          //   assets[0],
          //   end
          //   //mediaLibrary.getAssetUrl(assets[0].id)
          // );
          // console.log('[App.]', mediaLibrary.getAsset(assets[0].id));
          // setImage(assets[1].uri);
        }}
      >
        <Text>Photos</Text>
      </TouchableOpacity>
      {!!image && (
        <FastImage
          source={{ uri: image }}
          style={{ width: 100, height: 100, backgroundColor: 'red' }}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'white',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
