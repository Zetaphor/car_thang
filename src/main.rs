//#![allow(clippy::assigning_clones)]
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

extern crate image;

mod authentification;
mod playback_controls;

use authentification::{get_state_from_spotify, setup_spotify, update_state_item};
use image::EncodableLayout;
use playback_controls::{
    change_playback_state, get_buffer_and_location, get_image_url_of_current_song,
    get_name_of_current_song, guess_current_progress, like, shuffle, skip_backward, skip_forward,
    weak_update_state_item,
};
use std::time::Duration;

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
                .send("Deep Update")
                .await
                .expect("Couldn't update song");
            tokio::time::sleep(Duration::from_secs(30)).await;
        }
    });

    let time_tx = tx1.clone();
    tokio::task::spawn(async move {
        loop {
            time_tx
                .send("Update Progress")
                .await
                .expect("Couldn't update progress");
            tokio::time::sleep(Duration::from_millis(100)).await;
        }
    });

    let shuffle_tx = tx1.clone();
    ui.on_shuffle(move || {
        let use_tx1 = shuffle_tx.clone();
        tokio::task::spawn(async move {
            use_tx1
                .send("Shuffle")
                .await
                .expect("Couldn't Shuffle song");
        });
    });

    let like_tx = tx1.clone();
    ui.on_like(move || {
        let use_tx1 = like_tx.clone();
        tokio::task::spawn(async move {
            use_tx1.send("Like").await.expect("Couldn't Like song");
        });
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
            use_tx1
                .send("New Song")
                .await
                .expect("New song didn't work (forward)");
        });
    });

    let ui_handle = ui.as_weak();
    let _tokio_thread = tokio::spawn(async move {
        let spotify = setup_spotify().await;
        let mut state = get_state_from_spotify(&spotify).await;

        let (mut queue, mut loc_in_queue) = get_buffer_and_location(&spotify).await;

        loop {
            tokio::select! {
                val = rx1.recv() => {

                    match val.unwrap() {
                        "PlayPause" => {
                                let _ = change_playback_state(&spotify, &mut state).await;
                                guess_current_progress(&spotify, &mut state).await;
                                let ui2 = ui_handle.clone();
                                slint::invoke_from_event_loop(move || {
                                    let ui = ui2.unwrap();
                                    ui.set_paused(state.is_playing);

                                 }).unwrap();

                        },

                        "Update Progress" => {
                            let ui2 = ui_handle.clone();
                            guess_current_progress(&spotify, &mut state).await;
                            if state.percentage >= 1.0 {
                                update_state_item(&spotify, &mut state).await;
                            let (mut name, mut artist, mut album) = get_name_of_current_song(&spotify, &mut state).await.unwrap();
                            if name.len() > 19  {
                                name = name.chars().take(19).collect();
                                name.push_str("...");
                            }
                            if artist.len() > 30  {
                                artist = artist.chars().take(30).collect();
                                artist.push_str("...");
                            }
                            if album.len() > 30  {
                                album = album.chars().take(30).collect();
                                album.push_str("...");
                            }
                            let img = get_image_url_of_current_song(&spotify, &mut state).await.unwrap();
                            println!("Got new song: {:?}: {:?}", name, img);
                            let image_bytes = reqwest::get(&img).await.unwrap().bytes().await.unwrap();

                            slint::invoke_from_event_loop(move || {
                                let img = image::load_from_memory(&image_bytes).unwrap().into_rgba8();
                                let color = color_thief::get_palette(img.as_bytes(), color_thief::ColorFormat::Rgba, 5, 2).unwrap()[0];
                                let use_color = slint::Color::from_rgb_u8(color.r, color.g, color.b);
                                let whiten = (color.r as f32 * color.r as f32 + color.g as f32 * color.g as f32 + color.b as f32 * color.b as f32).sqrt() <= 120.0;
                                let shared_buf = SharedPixelBuffer::<Rgba8Pixel>::clone_from_slice(
                                    img.as_raw(),
                                    img.width(),
                                    img.height(),
                                );
                                let image = Image::from_rgba8(shared_buf);

                                let ui = ui2.unwrap();
                                ui.set_song_name(SharedString::from(name));
                                ui.set_artist_name(SharedString::from(artist));
                                ui.set_album_name(SharedString::from(album));
                                ui.set_song_image(image);
                                ui.set_background_color(use_color);
                                ui.set_use_white_text(whiten);
                                ui.set_paused(state.is_playing);
                                ui.set_shuffled(state.shuffle);
                                ui.set_liked(state.liked);
                                ui.set_time(state.percentage);
                            }).unwrap();

                            (queue,  loc_in_queue) = get_buffer_and_location(&spotify).await;
                            } else {
                                slint::invoke_from_event_loop(move || {
                                    let ui = ui2.unwrap();
                                    ui.set_time(state.percentage);
                                 }).unwrap();
                            }
                        },

                        "Shuffle" => {
                            let _ = shuffle(&spotify, &mut state).await;
                            let ui2 = ui_handle.clone();
                                slint::invoke_from_event_loop(move || {
                                    let ui = ui2.unwrap();
                                    ui.set_shuffled(state.shuffle);

                                 }).unwrap();
                        },

                        "Like" => {
                            let _ = like(&spotify, &mut state).await;
                            let ui2 = ui_handle.clone();
                                slint::invoke_from_event_loop(move || {
                                    let ui = ui2.unwrap();
                                    ui.set_liked(state.liked);
                                 }).unwrap();
                        },

                        "Back" => {
                            let _ = skip_backward(&spotify, &mut state).await;
                            if loc_in_queue > 0 {
                                loc_in_queue -= 1;

                                weak_update_state_item(&spotify, &mut state, &queue, &mut loc_in_queue).await;
                            } else {
                                update_state_item(&spotify, &mut state).await;
                            }
                        },

                        "Forward" => {
                            let _ = skip_forward(&spotify, &mut state).await;
                            if loc_in_queue < queue.len() - 1 {

                                weak_update_state_item(&spotify, &mut state, &queue, &mut loc_in_queue).await;
                                loc_in_queue += 1;

                            }
                        },

                        "Deep Update" => {

                            update_state_item(&spotify, &mut state).await;
                            let (mut name, mut artist, mut album) = get_name_of_current_song(&spotify, &mut state).await.unwrap();
                            if name.len() > 19  {
                                name = name.chars().take(19).collect();
                                name.push_str("...");
                            }
                            if artist.len() > 30  {
                                artist = artist.chars().take(30).collect();
                                artist.push_str("...");
                            }
                            if album.len() > 30  {
                                album = album.chars().take(30).collect();
                                album.push_str("...");
                            }
                            let img = get_image_url_of_current_song(&spotify, &mut state).await.unwrap();
                            println!("Got new song: {:?}: {:?}", name, img);
                            let image_bytes = reqwest::get(&img).await.unwrap().bytes().await.unwrap();

                            let ui2 = ui_handle.clone();
                            slint::invoke_from_event_loop(move || {
                                let img = image::load_from_memory(&image_bytes).unwrap().into_rgba8();
                                let color = color_thief::get_palette(img.as_bytes(), color_thief::ColorFormat::Rgba, 5, 2).unwrap()[0];
                                let use_color = slint::Color::from_rgb_u8(color.r, color.g, color.b);
                                let whiten = (color.r as f32 * color.r as f32 + color.g as f32 * color.g as f32 + color.b as f32 * color.b as f32).sqrt() <= 120.0;
                                let shared_buf = SharedPixelBuffer::<Rgba8Pixel>::clone_from_slice(
                                    img.as_raw(),
                                    img.width(),
                                    img.height(),
                                );
                                let image = Image::from_rgba8(shared_buf);

                                let ui = ui2.unwrap();
                                ui.set_song_name(SharedString::from(name));
                                ui.set_artist_name(SharedString::from(artist));
                                ui.set_album_name(SharedString::from(album));
                                ui.set_song_image(image);
                                ui.set_background_color(use_color);
                                ui.set_use_white_text(whiten);
                                ui.set_paused(state.is_playing);
                                ui.set_shuffled(state.shuffle);
                                ui.set_liked(state.liked);
                                ui.set_time(state.percentage);
                            }).unwrap();

                            (queue,  loc_in_queue) = get_buffer_and_location(&spotify).await;
                        },

                        "New Song" => {
                            let (mut name, mut artist, mut album) = get_name_of_current_song(&spotify, &mut state).await.unwrap();
                            if name.len() > 19  {
                                name = name.chars().take(19).collect();
                                name.push_str("...");
                            }
                            if artist.len() > 30  {
                                artist = artist.chars().take(30).collect();
                                artist.push_str("...");
                            }
                            if album.len() > 30  {
                                album = album.chars().take(30).collect();
                                album.push_str("...");
                            }
                            let img = get_image_url_of_current_song(&spotify, &mut state).await.unwrap();
                            println!("Got new song: {:?}: {:?}", name, img);
                            let image_bytes = reqwest::get(&img).await.unwrap().bytes().await.unwrap();

                            let ui2 = ui_handle.clone();
                            slint::invoke_from_event_loop(move || {
                                let img = image::load_from_memory(&image_bytes).unwrap().into_rgba8();
                                let color = color_thief::get_palette(img.as_bytes(), color_thief::ColorFormat::Rgba, 5, 2).unwrap()[0];
                                let use_color = slint::Color::from_rgb_u8(color.r, color.g, color.b);
                                let whiten = (color.r as f32 * color.r as f32 + color.g as f32 * color.g as f32 + color.b as f32 * color.b as f32).sqrt() <= 120.0;

                                let shared_buf = SharedPixelBuffer::<Rgba8Pixel>::clone_from_slice(
                                    img.as_raw(),
                                    img.width(),
                                    img.height(),
                                );
                                let image = Image::from_rgba8(shared_buf);

                                let ui = ui2.unwrap();
                                ui.set_song_name(SharedString::from(name));
                                ui.set_artist_name(SharedString::from(artist));
                                ui.set_album_name(SharedString::from(album));
                                ui.set_song_image(image);
                                ui.set_background_color(use_color);
                                ui.set_use_white_text(whiten);
                                ui.set_shuffled(state.shuffle);
                                ui.set_liked(state.liked);
                                ui.set_time(state.percentage);
                            }).unwrap();

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
