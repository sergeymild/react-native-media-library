import * as React from 'react';

import { StyleSheet, View, Text, TouchableOpacity, Image } from 'react-native';
import { mediaLibrary } from 'react-native-media-library';
import { useState } from 'react';

export default function App() {
  const [image, setImage] = useState();

  return (
    <View style={styles.container}>
      <TouchableOpacity
        style={{ height: 50 }}
        onPress={() => {
          const start = Date.now();
          const assets = mediaLibrary.getAssets({
            requestUrls: false,
          });
          const end = start - Date.now();
          console.log('[App.]', JSON.stringify(assets, undefined, 2));
          console.log(
            '[App.]',
            assets.length,
            end,
            mediaLibrary.getAssetUrl(assets[0].id)
          );
          // setImage(assets[2].url);
        }}
      >
        <Text>Photos</Text>
      </TouchableOpacity>
      {!!image && (
        <Image source={{ uri: image }} style={{ width: 100, height: 100 }} />
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
