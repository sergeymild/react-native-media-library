import * as React from 'react';

import { PermissionsAndroid, StyleSheet, View } from 'react-native';
import { ShowcaseApp } from '@gorhom/showcase-template';
import { screens } from './screens';

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

const author = {
  username: 'SergeyMild',
  url: 'https://github.com/sergeymild',
};


export default function App() {
  return (
    <View style={styles.container}>
      <ShowcaseApp
        name="Media Library"
        description={''}
        version={'0.0'}
        author={author}
        data={screens}
      />
    </View>
  );
}

// export default function App() {
//   const [image, setImage] = useState();
//   const [openCollection, setOpenCollection] = useState<string | undefined>();
//   // requestCameraPermission();
//   // if (true) {
//   //   return <ImagesMerge />;
//   // }
//
//   // if (openCollection) {
//   //   return <ImagesList collection={openCollection} />;
//   // }
//
//   // return <CropImageExample />;
//
//   // return <CollectionsList setOpenCollection={setOpenCollection} />;
//
//   return (
//     <View style={styles.container}>
//       <TouchableOpacity
//         style={{ height: 50 }}
//         onPress={async () => {
//           const start = Date.now();
//
//           //
//           // const result = await mediaLibrary.getAssets({
//           //   limit: 10,
//           //   sortBy: 'creationTime',
//           //   sortOrder: 'desc',
//           // });
//           // console.log('[App.]', result.length);
//           // for (let assetItem of result) {
//           //   console.log('[App.]', await mediaLibrary.getAsset(assetItem.id));
//           // }
//
//           console.log('[App.]', mediaLibrary.cacheDir);
//           // console.log('[App.]');
//           // const t = await mediaLibrary.imageResize({
//           //   width: 200,
//           //   format: 'png',
//           //   uri: `${mediaLibrary.cacheDir}/3.jpeg`,
//           //   resultSavePath: `${mediaLibrary.cacheDir}/result.png`,
//           // });
//           // console.log('[App.---- ]', t);
//           // const s = await mediaLibrary.getAssets({});
//           // console.log(
//           //   '[App.]',
//           //   s.find((ss) => ss.filename.startsWith('image.png'))
//           // );
//           // console.log(
//           //   '[App.]',
//           //   await mediaLibrary.imageSizes({
//           //     images: [
//           //       (await mediaLibrary.getAssets({ limit: 1 }))[0].uri,
//           //       `${mediaLibrary.cacheDir}/3.png`,
//           //       'https://upload.wikimedia.org/wikipedia/commons/7/70/Example.png',
//           //       require('../assets/3.png'),
//           //     ],
//           //   })
//           // );
//           // console.log('[App.imageSizes]');
//           const isSuccess = await mediaLibrary.combineImages({
//             images: [
//               `https://upload.wikimedia.org/wikipedia/commons/7/70/Example.png`,
//               require('../assets/3.png'),
//             ],
//             resultSavePath: `${__mediaLibrary.cacheDir()}/tmp/re/result.png`,
//           });
//           console.log(
//             '[App.save]',
//             isSuccess,
//             `${__mediaLibrary.cacheDir()}/tmp/re/result.png`
//           );
//           // const saveResponse = await mediaLibrary.saveToLibrary(
//           //   // `/data/user/0/com.example.reactnativemedialibrary/files/2222.jpg`
//           //   `${__mediaLibrary.docDir()}/ls.jpg`
//           // );
//           // console.log('[App.save]', saveResponse);
//
//           // requestCameraPermission();
//           // console.log(
//           //   '[App.]',
//           //   await FS.exists(`${FS.CachesDirectoryPath}/3.jpg`)
//           // );
//           // const response = await mediaLibrary.getAssets({
//           //   //onlyFavorites: true,
//           //   mediaType: ['video'],
//           // });
//           // for (let assetItem of response.filter(
//           //   (s) => s.mediaType === 'video'
//           // )) {
//           //   let newVar = await mediaLibrary.getAsset(assetItem.id);
//           //   console.log(
//           //     '[App.]',
//           //     newVar?.location,
//           //     newVar?.width,
//           //     newVar?.height
//           //   );
//           // }
//
//           // console.log(
//           //   '[App.]',
//           //   await mediaLibrary.fetchVideoFrame({
//           //     time: 6,
//           //     url: (
//           //       await mediaLibrary.getAsset(
//           //         response.filter((s) => s.mediaType === 'video')[0].id
//           //       )
//           //     )?.url,
//           //     quality: 0.4,
//           //   })
//           // );
//
//           // const saveR = await mediaLibrary.saveToLibrary({
//           //   // localUrl: `${__mediaLibrary.docDir()}/ls.jpg`,
//           //   localUrl: `/data/user/0/com.example.reactnativemedialibrary/files/2222.jpg`,
//           //   album: 'some',
//           // });
//           // console.log('[App.]', saveR);
//           // const assets = mediaLibrary.getAssets({
//           //   requestUrls: false,
//           //   limit: 1,
//           //   mediaType: ['photo'],
//           //   extensions: ['jpg'],
//           //   sortBy: 'creationTime',
//           //   sortOrder: 'asc',
//           // });
//           // console.log(
//           //   '[App.]',
//           //   assets.map((e) => e.creationTime)
//           // );
//           // const end = start - Date.now();
//           // // console.log('[App.]', JSON.stringify(assets, undefined, 2));
//           // console.log(
//           //   '[App.]',
//           //   assets.length,
//           //   assets[0],
//           //   end
//           //   //mediaLibrary.getAssetUrl(assets[0].id)
//           // );
//           // console.log('[App.]', mediaLibrary.getAsset(assets[0].id));
//           // setImage(assets[1].uri);
//         }}
//       >
//         <Text>Photos</Text>
//       </TouchableOpacity>
//       {!!image && (
//         <FastImage
//           source={{ uri: image }}
//           style={{ width: 100, height: 100, backgroundColor: 'red' }}
//         />
//       )}
//     </View>
//   );
// }

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexGrow: 1,
  }
});
