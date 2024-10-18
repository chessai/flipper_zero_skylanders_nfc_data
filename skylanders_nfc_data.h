#pragma once

#include <furi.h>
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

#define NFC_APP_FOLDER    ANY_PATH("nfc")
#define NFC_APP_EXTENSION ".nfc"
#define APP_TAG           "skylanders_nfc_data"

// Options:
// 1. Install to default directory (nfc/skylanders)
// 2. Choose directory (should be subdirectory of `nfc`)

// Failure modes
// 1. target directory already exists
typedef enum {
    Spyros_Adventure,
    Giants,
    Swap_Force,
    Trap_Team,
    Eons_Elite,
    Superchargers,
    Imaginators,
} SkylandersGame;

// Returns the name of the game as a formatted string.
// If somehow this switch statement is not exhaustive, it will log an error and return NULL.
char* skylanders_game_to_string(SkylandersGame game) {
    switch(game) {
    case Spyros_Adventure:
        return "Skylanders 1 - Spyro's Adventure";
    case Giants:
        return "Skylanders 2 - Giants";
    case Swap_Force:
        return "Skylanders 3 - Swap Force";
    case Trap_Team:
        return "Skylanders 4 - Trap Team";
    case Eons_Elite:
        return "Skylanders 4.5 - Eon's Elite";
    case Superchargers:
        return "Skylanders 5 - Superchargers";
    case Imaginators:
        return "Skylanders 6 - Imaginators";
    }
    FURI_LOG_E(APP_TAG, "Unknown SkylandersGame: %d", game);
    return NULL;
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
