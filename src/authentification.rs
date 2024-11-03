use rspotify::{prelude::OAuthClient, scopes, AuthCodeSpotify, Config, Credentials, OAuth};

use crate::State;

pub async fn setup_spotify() -> AuthCodeSpotify {
    let creds = Credentials::from_env().unwrap();

    let oauth = OAuth::from_env(scopes!(
        "user-read-playback-state",
        "user-modify-playback-state",
        "user-read-currently-playing",
        "app-remote-control",
        "playlist-read-private",
        "playlist-read-collaborative",
        "playlist-modify-private",
        "playlist-modify-public",
        "user-read-playback-position",
        "user-read-recently-played",
        "user-library-modify",
        "user-library-read"
    ))
    .unwrap();

    let spotify = AuthCodeSpotify::with_config(
        creds,
        oauth,
        Config {
            token_cached: true,
            ..Default::default()
        },
    );

    let url = spotify.get_authorize_url(false).unwrap();

    spotify.prompt_for_token(&url).await.unwrap();
    spotify
}

pub async fn get_state_from_spotify(spotify: &AuthCodeSpotify) -> State {
    let current = spotify.current_playing(None, None::<Vec<_>>).await;

    let use_current = current.unwrap().unwrap().clone();

    let is_playing = use_current.is_playing;
    let progress_ms = use_current.progress.unwrap();
    let item = use_current.item;

    let devices = spotify.device().await.expect("Could not get deivces");
    let device = devices
        .iter()
        .find(|device| device.is_active)
        .unwrap()
        .id
        .clone();

    State {
        is_playing,
        progress_ms,
        item,
        device,
    }
}

pub async fn update_state_item(spotify: &AuthCodeSpotify, state: &mut State) {
    let current = spotify.current_playing(None, None::<Vec<_>>).await;

    let use_current = current.unwrap().unwrap().clone();

    state.is_playing = use_current.is_playing;
    state.progress_ms = use_current.progress.unwrap();
    state.item = use_current.item;
}
