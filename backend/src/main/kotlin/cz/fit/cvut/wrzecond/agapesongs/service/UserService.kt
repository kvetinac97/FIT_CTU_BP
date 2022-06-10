package cz.fit.cvut.wrzecond.agapesongs.service

import cz.fit.cvut.wrzecond.agapesongs.dto.*
import cz.fit.cvut.wrzecond.agapesongs.entity.*
import cz.fit.cvut.wrzecond.agapesongs.repository.UserRepository
import org.springframework.stereotype.Service
import kotlin.random.Random

@Service
class UserService (override val repository: UserRepository) : IServiceBase<User>(repository, repository) {

    /** Function to get user by login secret */
    fun getByLoginSecret (loginSecret: String)
        = repository.getByLoginSecret(loginSecret)?.toDTO()

    /** Function to get user with given email. If no user exists, creates one with given name */
    fun getOrCreate (email: String, name: String) = tryCatch {
        repository.getByEmail(email) ?: saveAndFlush(UserCreateDTO(email, name).toEntity())
    }

    // === HELPER METHODS ===
    private fun User.toDTO () = UserReadDTO(id, email, name, bands.map { it.toDTO() })
    private fun UserCreateDTO.toEntity () = User(generateLoginSecret(), email, name, emptyList(), emptyList())
    private fun generateLoginSecret () = (1..LOGIN_SECRET_LENGTH)
        .map { Random.nextInt(0, CHAR_POOL.size) }
        .map(CHAR_POOL::get)
        .joinToString("")
    private fun BandMember.toDTO () = BandMemberReadDTO(id, band.toDTO(),
        UserReadDTO(user.id, user.email, user.name, emptyList()), role.toDTO())
    private fun Band.toDTO ()     = BandReadDTO(id, name, emptyList())
    private fun Role.toDTO ()     = RoleReadDTO(id, level.name)
    // === HELPER METHODS ===

    companion object {
        private const val LOGIN_SECRET_LENGTH = 16
        private val CHAR_POOL = ('a'..'z') + ('A'..'Z') + ('0'..'9')
    }
}
