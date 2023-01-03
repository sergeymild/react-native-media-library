import * as React from 'react';

import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  Image,
  PermissionsAndroid,
} from 'react-native';
import { mediaLibrary } from 'react-native-media-library';
import { useState } from 'react';
import FastImage from 'react-native-fast-image';
import FS, { getAllExternalFilesDirs } from 'react-native-fs';

const requestCameraPermission = async () => {
  try {
    const granted = await PermissionsAndroid.request(
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.ACCESS_MEDIA_LOCATION'
    );
    if (granted === PermissionsAndroid.RESULTS.GRANTED) {
      console.log('You can use the camera');
    } else {
      console.log('Camera permission denied');
    }
  } catch (err) {
    console.warn(err);
  }
};

export default function App() {
  const [image, setImage] = useState();

  console.log('[App.App]', image);

  return (
    <View style={styles.container}>
      <TouchableOpacity
        style={{ height: 50 }}
        onPress={async () => {
          const start = Date.now();

          await requestCameraPermission();
          //
          // const result = await mediaLibrary.getAssets({
          //   limit: 10,
          //   sortBy: 'creationTime',
          //   sortOrder: 'desc',
          // });
          // console.log('[App.]', result.length);
          // for (let assetItem of result) {
          //   console.log('[App.]', await mediaLibrary.getAsset(assetItem.id));
          // }

          console.log('[App.]', mediaLibrary.cacheDir);
          // console.log('[App.]');
          const t = await mediaLibrary.imageResize({
            width: 200,
            format: 'png',
            uri: `${mediaLibrary.cacheDir}/3.jpeg`,
            resultSavePath: `${mediaLibrary.cacheDir}/result.png`,
          });
          console.log('[App.---- ]', t);
          // console.log(
          //   '[App.]',
          //   await mediaLibrary.imageSizes({
          //     images: [
          //       (await mediaLibrary.getAssets({ limit: 1 }))[0].uri,
          //       `${mediaLibrary.cacheDir}/3.png`,
          //       'https://upload.wikimedia.org/wikipedia/commons/7/70/Example.png',
          //       require('../assets/3.png'),
          //     ],
          //   })
          // );
          // console.log('[App.imageSizes]');
          // const isSuccess = await mediaLibrary.combineImages({
          //   images: [
          //     `${__mediaLibrary.docDir()}/1.png`,
          //     `https://upload.wikimedia.org/wikipedia/commons/7/70/Example.png`,
          //     require('../assets/3.png'),
          //   ],
          //   resultSavePath: `${__mediaLibrary.docDir()}/tmp/re/result.png`,
          // });
          // console.log(
          //   '[App.save]',
          // );
          // const saveResponse = await mediaLibrary.saveToLibrary(
          //   // `/data/user/0/com.example.reactnativemedialibrary/files/2222.jpg`
          //   `${__mediaLibrary.docDir()}/ls.jpg`
          // );
          // console.log('[App.save]', saveResponse);

          // requestCameraPermission();
          // console.log(
          //   '[App.]',
          //   await FS.exists(`${FS.CachesDirectoryPath}/3.jpg`)
          // );
          // const response = await mediaLibrary.getAssets({
          //   //onlyFavorites: true,
          //   mediaType: ['video'],
          // });
          // for (let assetItem of response.filter(
          //   (s) => s.mediaType === 'video'
          // )) {
          //   let newVar = await mediaLibrary.getAsset(assetItem.id);
          //   console.log(
          //     '[App.]',
          //     newVar?.location,
          //     newVar?.width,
          //     newVar?.height
          //   );
          // }

          // console.log(
          //   '[App.]',
          //   await mediaLibrary.fetchVideoFrame({
          //     time: 6,
          //     url: (
          //       await mediaLibrary.getAsset(
          //         response.filter((s) => s.mediaType === 'video')[0].id
          //       )
          //     )?.url,
          //     quality: 0.4,
          //   })
          // );

          // const saveR = await mediaLibrary.saveToLibrary({
          //   // localUrl: `${__mediaLibrary.docDir()}/ls.jpg`,
          //   localUrl: `/data/user/0/com.example.reactnativemedialibrary/files/2222.jpg`,
          //   album: 'some',
          // });
          // console.log('[App.]', saveR);
          // const assets = mediaLibrary.getAssets({
          //   requestUrls: false,
          //   limit: 1,
          //   mediaType: ['photo'],
          //   extensions: ['jpg'],
          //   sortBy: 'creationTime',
          //   sortOrder: 'asc',
          // });
          // console.log(
          //   '[App.]',
          //   assets.map((e) => e.creationTime)
          // );
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
    backgroundColor: 'red',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
