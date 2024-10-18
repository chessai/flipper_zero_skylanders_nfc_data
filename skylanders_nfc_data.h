#pragma once

#include <furi.h>
#include <storage/storage.h>
#include <gui/gui.h>
#include <gui/icon_i.h>
#include <gui/view_dispatcher.h>
#include <gui/scene_manager.h>
#include <gui/modules/menu.h>
#include <gui/modules/popup.h>
#include <gui/modules/submenu.h>
#include <gui/modules/popup.h>
#include <gui/modules/loading.h>
#include <gui/modules/text_input.h>
#include <gui/modules/byte_input.h>
#include <gui/modules/widget.h>
#include "skylanders_data/headers/skylanders_assets.h"

#define NFC_APP_FOLDER    ANY_PATH("nfc")
#define NFC_APP_EXTENSION ".nfc"
#define APP_TAG           "skylanders_nfc_data"

// Options:
// 1. Install to default directory (nfc/skylanders)
// 2. Choose directory (should be subdirectory of `nfc`)

// Failure modes
// 1. target directory already exists

/*
typedef enum {
    Spyros_Adventure,
    Giants,
    Swap_Force,
    Trap_Team,
    Eons_Elite,
    Superchargers,
    Imaginators,
} SkylandersGame;
*/

// Returns the name of the game as a formatted string.
// If somehow this switch statement is not exhaustive, it will log an error and return NULL.
char* skylanders_game_to_string(const char* game) {
    if(strcmp(game, "Spyros_Adventure") == 0) {
        return "Skylanders 1 - Spyro's Adventure";
    } else if(strcmp(game, "Giants") == 0) {
        return "Skylanders 2 - Giants";
    } else if(strcmp(game, "Swap_Force") == 0) {
        return "Skylanders 3 - Swap Force";
    } else if(strcmp(game, "Trap_Team") == 0) {
        return "Skylanders 4 - Trap Team";
    } else if(strcmp(game, "Eons_Elite") == 0) {
        return "Skylanders 4.5 - Eon's Elite";
    } else if(strcmp(game, "Superchargers") == 0) {
        return "Skylanders 5 - Superchargers";
    } else if(strcmp(game, "Imaginators") == 0) {
        return "Skylanders 6 - Imaginators";
    } else {
        FURI_LOG_E(APP_TAG, "Unknown SkylandersGame: %s", game);
        return NULL;
    }
}

bool write_asset(Asset* asset) {
    char path_buffer[512];
    snprintf(
        path_buffer,
        512, // 512 should fit anything possible
        "%s%s%s%s%s%s%s%s%s",
        NFC_APP_FOLDER,
        "/",
        "skylanders",
        "/",
        skylanders_game_to_string(asset->game),
        "/",
        asset->type,
        "/",
        asset->name);

    Storage* storage = furi_record_open(RECORD_STORAGE);
    File* file = storage_file_alloc(storage);

    bool result = storage_file_open(file, path_buffer, FSAM_WRITE, FSOM_CREATE_ALWAYS);
    if(result) {
        storage_file_write(file, asset->data, asset->data_len);
        storage_file_close(file);
    } else {
        FURI_LOG_E("Failed to open or create file: %s", path_buffer);
    }

    storage_file_free(file);
    furi_record_close(RECORD_STORAGE);
    return result;
}

bool write_skylanders_nfc_data() {
    bool result = true;
    initialize_assets();

    for(int i = 0; i < ASSET_COUNT; i++) {
        result &= write_asset(assets[i]);
    }

    return result;
}

typedef enum {
    Scene_MainMenu,
} SkylandersScene;

typedef enum {
    View_Menu,
} SkylandersView;

typedef enum {
    Event_One,
} SkylandersEvent;

typedef enum {
    MenuItem_One,
} SkylandersMenuItem;

typedef struct {
    SceneManager* scene_manager;
    ViewDispatcher* view_dispatcher;
    Menu* menu;
    Popup* popup;
} SkylandersApp;

SkylandersApp* skylanders_nfc_data_app_init() {
    FURI_LOG_T(APP_TAG, "skylanders_nfc_data_app_init");
    SkylandersApp* app = malloc(sizeof(SkylandersApp));
    // TODO uninitialised app
    return app;
}
void skylanders_nfc_data_app_free(SkylandersApp* app) {
    FURI_LOG_T(APP_TAG, "skylanders_nfc_data_app_free");
    scene_manager_free(app->scene_manager);
    view_dispatcher_remove_view(app->view_dispatcher, View_Menu);
    view_dispatcher_free(app->view_dispatcher);
    menu_free(app->menu);
    popup_free(app->popup);
    free(app);
}

/** go to trace log level in the dev environment */
void set_log_level() {
#ifdef FURI_DEBUG
    furi_log_set_level(FuriLogLevelTrace);
#else
    furi_log_set_level(FuriLogLevelInfo);
#endif
}
