export const screens = [
  {
    title: 'Media',
    data: [
      {
        name: 'CollectionsList',
        slug: 'CollectionsList',
        getScreen: () => require('./modal/CollectionsList').CollectionsList,
      },
      {
        name: 'ImagesList',
        slug: 'ImagesList',
        getScreen: () => require('./modal/ImagesList').ImagesList,
      },
      {
        name: 'SloMo',
        slug: 'SloMo',
        getScreen: () => require('./modal/SloMo').SloMo,
      },
      {
        name: 'ExportVideo',
        slug: 'ExportVideo',
        getScreen: () => require('./modal/ExportVideo').ExportVideo,
      },
    ],
  },
];
