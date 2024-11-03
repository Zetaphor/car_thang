//#![allow(clippy::assigning_clones)]
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

extern crate image;

mod authentification;
mod playback_controls;

use authentification::{get_state_from_spotify, setup_spotify, update_state_item};
use playback_controls::{
    change_playback_state, get_image_url_of_current_song, get_name_of_current_song, skip_backward,
    skip_forward, State,
};
use std::{
    borrow::BorrowMut,
    fs::File,
    io::{BufReader, Read},
    os::unix::thread,
    sync::Arc,
    time::Duration,
};

use rspotify::{model::TrackId, prelude::*};
use tokio::sync::mpsc;

use slint::{Image, Rgba8Pixel, SharedPixelBuffer, SharedString};

slint::include_modules!();

#[tokio::main]
async fn main() {
    // Setup
    env_logger::init();
    // let spotify = setup_spotify().await;
    // let mut state = get_state_from_spotify(&spotify).await;

    let ui = AppWindow::new().unwrap();

    let (tx1, mut rx1) = mpsc::channel(32);

    let starting_tx = tx1.clone();
    tokio::task::spawn(async move {
        starting_tx
            .send("New Song")
            .await
            .expect("Couldn't start songs up");
    });

    let play_pause_tx = tx1.clone();
    ui.on_play_pause(move || {
        let use_tx1 = play_pause_tx.clone();
        tokio::task::block_in_place(move || {
            use_tx1.blocking_send("PlayPause").unwrap();
        })
    });

    let update_tx = tx1.clone();
    tokio::task::spawn(async move {
        loop {
            update_tx
                .send("New Song")
                .await
                .expect("Couldn't update song");
            tokio::time::sleep(Duration::from_secs(5)).await;
        }
    });

    let backward_tx = tx1.clone();
    ui.on_skip_backward(move || {
        let use_tx1 = backward_tx.clone();
        tokio::task::spawn(async move {
            use_tx1
                .send("Back")
                .await
                .expect("Sending back didn't work");
            tokio::time::sleep(Duration::from_millis(500)).await;
            use_tx1
                .send("New Song")
                .await
                .expect("New song didn't work (back)");
        });
    });

    let forward_tx = tx1.clone();
    ui.on_skip_forward(move || {
        let use_tx1 = forward_tx.clone();
        tokio::task::spawn(async move {
            use_tx1
                .send("Forward")
                .await
                .expect("Sending forward didn't work");
            tokio::time::sleep(Duration::from_millis(500)).await;
            use_tx1
                .send("New Song")
                .await
                .expect("New song didn't work (forward)");
        });
    });
    let image_bytes = Arc::new(vec![
        std::fs::read("ui/res/back_button.png").unwrap(),
        std::fs::read("ui/res/forward_button.png").unwrap(),
        std::fs::read("ui/res/pause_button.png").unwrap(),
        std::fs::read("ui/res/play_button.png").unwrap(),
    ]);

    let ui_handle = ui.as_weak();
    let tokio_thread = tokio::spawn(async move {
        let spotify = setup_spotify().await;
        let mut state = get_state_from_spotify(&spotify).await;

        let img_bytes = image_bytes.clone();

        loop {
            tokio::select! {
                val = rx1.recv() => {

                    match val.unwrap() {
                        "PlayPause" => {
                                let _ = change_playback_state(&spotify, &mut state).await;
                                let new_image = if state.is_playing {
                                    2
                                } else {
                                    3
                                };
                                let ui2 = ui_handle.clone();
                                let img_bytes2 = img_bytes.clone();
                                slint::invoke_from_event_loop(move || {
                                    let ui = ui2.unwrap();
                                    let img = image::load_from_memory(&img_bytes2[new_image]).unwrap().into_rgba8();
                                    let shared_buf = SharedPixelBuffer::<Rgba8Pixel>::clone_from_slice(
                                        img.as_raw(),
                                        img.width(),
                                        img.height(),
                                    );
                                    let image = Image::from_rgba8(shared_buf);
                                    ui.set_pp(image);

                                 }).unwrap();

                        },
                        "Back" => {
                            let _ = skip_backward(&spotify, &mut state).await;
                            update_state_item(&spotify, &mut state).await;
                        },

                        "Forward" => {
                            let _ = skip_forward(&spotify, &mut state).await;
                            update_state_item(&spotify, &mut state).await;
                            println!("We went forward");
                        },

                        "New Song" => {
                            update_state_item(&spotify, &mut state).await;
                            let name = get_name_of_current_song(&spotify, &mut state).await.unwrap();
                            let img = get_image_url_of_current_song(&spotify, &mut state).await.unwrap();
                            println!("Got new song: {:?}: {:?}", name, img);
                            let image_bytes = reqwest::get(&img).await.unwrap().bytes().await.unwrap();

                            let ui2 = ui_handle.clone();
                            slint::invoke_from_event_loop(move || {
                                let img = image::load_from_memory(&image_bytes).unwrap().into_rgba8();
                                let shared_buf = SharedPixelBuffer::<Rgba8Pixel>::clone_from_slice(
                                    img.as_raw(),
                                    img.width(),
                                    img.height(),
                                );
                                let image = Image::from_rgba8(shared_buf);

                                let ui = ui2.unwrap();
                                ui.set_song_name(SharedString::from(name));
                                ui.set_song_image(image);
                            }).unwrap();

                            println!("Queue: {:?}", spotify.current_user_queue().await.unwrap().queue.len());

                        },
                        _ => {
                            println!("Received unknown value");
                        },
                    }


                }

            }
        }
    });

    ui.run().unwrap();
}
