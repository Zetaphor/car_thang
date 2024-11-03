use chrono::TimeDelta;
use rspotify::{
    model::{Id, PlayableItem, TrackId},
    prelude::{BaseClient, OAuthClient},
    AuthCodeSpotify, ClientError,
};

pub struct State {
    pub is_playing: bool,
    pub progress_ms: TimeDelta,
    pub item: Option<PlayableItem>,
    pub device: Option<String>,
}

pub async fn change_playback_state(
    spotify: &AuthCodeSpotify,
    state: &mut State,
) -> Result<(), ClientError> {
    let device = state.device.clone();

    if state.is_playing {
        state.is_playing = false;
        spotify.pause_playback(device.as_deref()).await
    } else {
        state.is_playing = true;
        spotify.resume_playback(device.as_deref(), None).await
    }
}

pub async fn skip_forward(spotify: &AuthCodeSpotify, state: &mut State) -> Result<(), ClientError> {
    let device = state.device.clone();
    spotify.next_track(device.as_deref()).await
}

pub async fn skip_backward(
    spotify: &AuthCodeSpotify,
    state: &mut State,
) -> Result<(), ClientError> {
    let device = state.device.clone();
    spotify.previous_track(device.as_deref()).await
}

pub async fn get_name_of_current_song(
    spotify: &AuthCodeSpotify,
    state: &mut State,
) -> Result<String, ClientError> {
    let binding = state.item.clone().unwrap();
    let binding = binding.id().unwrap();
    let track_id = TrackId::from_id(binding.id()).unwrap();
    let track = spotify.track(track_id, None).await.unwrap();
    Ok(track.name)
}

pub async fn get_image_url_of_current_song(
    spotify: &AuthCodeSpotify,
    state: &mut State,
) -> Result<String, ClientError> {
    let binding = state.item.clone().unwrap();
    let binding = binding.id().unwrap();
    let track_id = TrackId::from_id(binding.id()).unwrap();
    let track = spotify.track(track_id, None).await.unwrap();
    let img = track.album.images[0].url.clone();
    Ok(img)
}
