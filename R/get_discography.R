#' Retrieve artist discography with song lyrics and audio info
#'
#' Retrieve the entire discography of an artist with the lyrics of each song and the associated audio information. Returns the song data as a nested tibble. This way we can easily see each album, artist, and song title before expanding our data.
#' @param artist The quoted name of the artist. Spelling matters, capitalization does not.
#'
#'
#' @examples
#' rex_orange <- get_discography("Rex Orange County")
#' unnest(rex_orange, data)
#'
#' @export
#' @import dplyr
#' @import geniusR
#' @importFrom tidyr nest unnest
#' @importFrom purrr possibly

get_discography <- function(artist) {

    # Identify All Albums for a single artist
    artist_audio_features <- get_artist_audio_features(artist) %>%
        group_by(album_name) %>%
        mutate(track_n = row_number())

    # Identify each unique album name and artist pairing
    album_list <- artist_audio_features %>%
        distinct(album_name) %>%
        mutate(artist = artist)

    # Create possible_album for potential error handling
    possible_album <- possibly(genius_album, otherwise = as_tibble())

    album_lyrics <- map2(album_list$artist, album_list$album_name, function(x, y) possible_album(x, y) %>% mutate(album_name = y)) %>%
        map_df(function(x) {
            if (nrow(x) > 0) {
                nest(x, -c(track_title, track_n, album_name))
            } else {
                tibble()
            }
        }) %>%
        rename(lyrics = data) %>%
        select(-track_title)

    # Acquire the lyrics for each track
    album_data <- artist_audio_features %>%
        left_join(album_lyrics, by = c('album_name', 'track_n'))

    return(album_data)
}



