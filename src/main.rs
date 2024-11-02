#![allow(clippy::assigning_clones)]

mod authentification;
mod playback_controls;

use std::{borrow::BorrowMut, time::Duration};
use authentification::{get_state_from_spotify, setup_spotify, update_state_item};
use playback_controls::{change_playback_state, get_name_of_current_song, skip_backward, skip_forward, State};


use rspotify::{model::TrackId, prelude::*};



#[tokio::main]
async fn main() {
    // Setup
    env_logger::init();
    let spotify = setup_spotify().await;
    let mut state = get_state_from_spotify(&spotify).await;


    // Testing

    let a =  skip_forward(&spotify, &mut state).await;
    update_state_item(&spotify, &mut state).await;
    let track_name = get_name_of_current_song(&spotify, &mut state).await;
    println!("{:?}, new song: {:?}", a, track_name.unwrap());

    tokio::time::sleep(Duration::from_secs(1)).await;

    let a =  skip_forward(&spotify, &mut state).await;
    update_state_item(&spotify, &mut state).await;
    let track_name = get_name_of_current_song(&spotify, &mut state).await;
    println!("{:?}, new song: {:?}", a, track_name.unwrap());


    tokio::time::sleep(Duration::from_secs(1)).await;
    let b =  skip_backward(&spotify, &mut state).await;
    update_state_item(&spotify, &mut state).await;
    let track_name = get_name_of_current_song(&spotify, &mut state).await;
    println!("{:?}, new song: {:?}", b, track_name.unwrap());

    tokio::time::sleep(Duration::from_secs(1)).await;

    let b =  skip_backward(&spotify, &mut state).await;
    update_state_item(&spotify, &mut state).await;
    let track_name = get_name_of_current_song(&spotify, &mut state).await;
    println!("{:?}, new song: {:?}", b, track_name.unwrap());

}

