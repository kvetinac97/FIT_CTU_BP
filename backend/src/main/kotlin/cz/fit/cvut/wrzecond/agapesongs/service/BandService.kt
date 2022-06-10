package cz.fit.cvut.wrzecond.agapesongs.service

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import cz.fit.cvut.wrzecond.agapesongs.dto.*
import cz.fit.cvut.wrzecond.agapesongs.entity.Band
import cz.fit.cvut.wrzecond.agapesongs.entity.BandMember
import cz.fit.cvut.wrzecond.agapesongs.entity.Role
import cz.fit.cvut.wrzecond.agapesongs.entity.User
import cz.fit.cvut.wrzecond.agapesongs.repository.BandRepository
import cz.fit.cvut.wrzecond.agapesongs.repository.SongRepository
import cz.fit.cvut.wrzecond.agapesongs.repository.UserRepository
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException
import java.text.Collator
import java.util.Locale

@Service
class BandService (override val repository: BandRepository, private val songRepository: SongRepository,
                   private val userRepository: UserRepository)
    : IServiceImpl<Band, BandReadDTO, BandCreateDTO, BandUpdateDTO>(repository, userRepository) {

    /** Find all bands in database sorted by name in czech locale */
    override fun findAll (user: UserReadDTO?) = super.findAll(user).sortedWith(
        compareBy(Collator.getInstance(Locale("cs_CZ"))) { it.name }
    )

    /**
     * Function to get playlist of given band
     * @param id identifier of band from which playlist will be fetched
     * @param user identification object for authenticating currently logged user
     * @return PlaylistDTO containing identifiers of songs in band playlist
     * @throws ResponseStatusException on failure
     */
    fun getPlaylist (id: Int, user: UserReadDTO?) = tryCatch {
        val band = getBandOrThrow(id, user) { canView(it) }
        val intArrayType = object: TypeToken<List<Int>>(){}.type
        val songIds: List<Int> = Gson().fromJson(band.playlist, intArrayType)
        val songs = songRepository.findByIds(songIds)
        PlaylistDTO(songIds.mapNotNull { songId -> songs.find { song -> song.id == songId }?.id })
    }

    /**
     * Function to save playlist of given band
     * @param id identifier of band to which playlist will be saved
     * @param playlist playlist object containing song ids to be saved
     * @param user identification object for authenticating currently logged user
     * @return PlaylistDTO containing identifiers of songs in band playlist
     * @throws ResponseStatusException on failure
     */
    fun putPlaylist (id: Int, playlist: PlaylistDTO, user: UserReadDTO?) = tryCatch {
        val band = getBandOrThrow(id, user) { canEdit(it) }
        val songs = songRepository.findByIds(playlist.songs)
        val matchedSongs = playlist.songs.mapNotNull { songId -> songs.find { song -> song.id == songId }?.id }
        val newBand = band.copy(playlist = Gson().toJson(matchedSongs))
        repository.saveAndFlush(newBand)
        PlaylistDTO(matchedSongs)
    }

    // === INTERFACE METHOD IMPLEMENTATION ===
    override fun Band.toDTO () = BandReadDTO(id, name, members.map { it.toDTO() })
    override fun BandCreateDTO.toEntity () = Band(name, "[]", emptyList(), emptyList())
    override fun Band.merge (dto: BandUpdateDTO) = Band (
        dto.name ?: name,
        playlist, members, songBooks,
        id
    )
    // === INTERFACE METHOD IMPLEMENTATION ===

    // === HELPER METHODS ===
    private fun BandMember.toDTO () = BandMemberReadDTO(id, BandReadDTO(band.id,
        band.name, emptyList()), user.toDTO(), role.toDTO())
    private fun User.toDTO () = UserReadDTO(id, email, name, emptyList())
    private fun Role.toDTO () = RoleReadDTO(id, level.name)
    // === HELPER METHODS ===

    // === PRIVATE HELPERS ===
    private fun getBandOrThrow(id: Int, user: UserReadDTO?, check: Band.(User) -> Boolean) = tryCatch {
        val band = getById(id)
        val userEntity = user?.let { userRepository.getByEmail(it.email) } ?: throw ResponseStatusException(HttpStatus.UNAUTHORIZED)
        if (!check(band, userEntity)) throw ResponseStatusException(HttpStatus.FORBIDDEN)
        band
    }
    // === PRIVATE HELPERS ===

}
