import React, { useEffect, useState } from 'react';
import { View } from 'react-native';
import { mediaLibrary } from 'react-native-media-library';
import Video from 'react-native-video';

export const SloMo: React.FC = () => {
  const [asset, setAsset] = useState<any>();

  useEffect(() => {
    mediaLibrary
      .getAssets({
        mediaType: ['video'],
        sortBy: 'creationTime',
        sortOrder: 'desc',
        limit: 1,
      })
      .then(async (r) => {
        //setAsset(r[0]);
        mediaLibrary.getAsset(r[0].id).then((rr) => {
          console.log('[SloMo.2]', rr?.url);
          setAsset(rr);
        });
      });
  }, []);

  console.log('[SloMo.SloMo!!]', asset?.uri);
  return (
    <View style={{ flex: 1 }}>
      {!!asset && (
        <Video
          // rate={rate}
          style={{ width: 200, height: 200 }}
          repeat
          // onLoad={({ duration }) => (durationRef.current = duration)}
          // onProgress={checkCurrentTime}
          source={{
            // uri: convertLocalIdentifierToAssetLibrary(
            //   asset.uri.replace('ph://', ''),
            //   'mov'
            // ),
            uri: asset.uri,
          }}
        />
      )}
    </View>
  );
};
