
#include "MediaAssetFileNative.h"
#include <errno.h>
#include <algorithm>
#include <sys/types.h>
#include <sys/xattr.h>

static int exclude_extradir_cb(const dirent* de) {
    int retVal = 1;
    if (de->d_type == DT_DIR) {
        char *mutablePath = strdup(de->d_name);
        char *filename = basename(mutablePath);
        retVal = (strcmp(filename, ".") != 0 && strcmp(filename, "..") != 0);
        free(mutablePath);
    }
    return retVal;
}

MediaAssetFileNative::File createFrom(const char *parentPath, dirent *entr) {
    MediaAssetFileNative::File file;
    const char *filename = entr->d_name;

    char fullPath[1024];
    snprintf(fullPath, sizeof(fullPath), "%s/%s", parentPath, filename);

    file.name = filename;
    file.isDir = entr->d_type == DT_DIR;
    file.absolutePath = fullPath;
    file.lastModificationTime = 0;
    file.size = 0;

    struct stat fileAttrs;
    if (stat(fullPath, &fileAttrs) == 0) {
        file.size = fileAttrs.st_size;
        file.lastModificationTime = fileAttrs.st_mtim.tv_sec * 1000;
    }

    return file;
}

struct sort_by_date {
    int multiplier;
    sort_by_date(int _multiplier): multiplier(_multiplier) {};

    inline bool operator() (const MediaAssetFileNative::File& lhs, const MediaAssetFileNative::File& rhs) {
        if (lhs.isDir && !rhs.isDir) return true;
        if (!lhs.isDir && rhs.isDir) return false;

        return multiplier > 0
               ? lhs.lastModificationTime < rhs.lastModificationTime
               : lhs.lastModificationTime > rhs.lastModificationTime;
    }
};


void MediaAssetFileNative::getFilesList(const char *path, const char *sortType, fileVector_t *fileList) {
    fileList->clear();
    dirent **namelist;
    int filesCount;
    filesCount = scandir(path, &namelist, &exclude_extradir_cb, nullptr);
    if (filesCount < 0) {
        return;
    }

    fileList->reserve(filesCount);

    for(int i = 0; i < filesCount; i++) {
        const char *filename = namelist[i]->d_name;
        auto isHidden = (strcmp(filename, ".") == 0 || strcmp(filename, "..") == 0);
        if (isHidden) {
            continue;
        }
        MediaAssetFileNative::File file = createFrom(path, namelist[i]);

        fileList->push_back(file);
        free(namelist[i]);
    }

    free(namelist);

    if (strcmp(sortType, "modificationTime_asc") == 0) {
        std::sort(fileList->begin(), fileList->end(), sort_by_date(1));
    } else if (strcmp(sortType, "modificationTime_desc") == 0) {
        std::sort(fileList->begin(), fileList->end(), sort_by_date(-1));
    }
}
