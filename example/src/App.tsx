import * as React from 'react';
import {
  PermissionsAndroid,
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  FlatList,
  SafeAreaView,
} from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import { CollectionsList } from './screens/modal/CollectionsList';
import { ImagesList } from './screens/modal/ImagesList';
import { SloMo } from './screens/modal/SloMo';
import { ExportVideo } from './screens/modal/ExportVideo';
import { Base64Image } from './screens/modal/Base64Image';
import { CombineImages } from './screens/modal/CombineImages';

const Stack = createNativeStackNavigator();

const screens = [
  { name: 'CollectionsList', component: CollectionsList },
  { name: 'ImagesList', component: ImagesList },
  { name: 'SloMo', component: SloMo },
  { name: 'ExportVideo', component: ExportVideo },
  { name: 'Base64Image', component: Base64Image },
  { name: 'CombineImages', component: CombineImages },
];

function HomeScreen({ navigation }: { navigation: any }) {
  React.useEffect(() => {
    PermissionsAndroid.requestMultiple([
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.ACCESS_MEDIA_LOCATION',
      'android.permission.READ_MEDIA_IMAGES',
      'android.permission.READ_MEDIA_VIDEO',
    ]).catch(console.warn);
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.header}>Media Library Examples</Text>
      <FlatList
        data={screens}
        keyExtractor={(item) => item.name}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.button}
            onPress={() => navigation.navigate(item.name)}
          >
            <Text style={styles.buttonText}>{item.name}</Text>
          </TouchableOpacity>
        )}
      />
    </SafeAreaView>
  );
}

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          headerStyle: { backgroundColor: '#6200ee' },
          headerTintColor: '#fff',
        }}
      >
        <Stack.Screen
          name="Home"
          component={HomeScreen}
          options={{ title: 'Media Library' }}
        />
        {screens.map((screen) => (
          <Stack.Screen
            key={screen.name}
            name={screen.name}
            component={screen.component}
          />
        ))}
      </Stack.Navigator>
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    fontSize: 24,
    fontWeight: 'bold',
    padding: 20,
    textAlign: 'center',
  },
  list: {
    padding: 16,
  },
  button: {
    backgroundColor: '#6200ee',
    padding: 16,
    borderRadius: 8,
    marginBottom: 12,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
