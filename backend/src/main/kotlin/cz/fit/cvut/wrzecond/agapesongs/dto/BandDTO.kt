package cz.fit.cvut.wrzecond.agapesongs.dto

/**
 * Data transfer object for band list
 * @property id unique identifier of band
 * @property name band name
 * @property members list of band members
 */
data class BandReadDTO (override val id: Int, val name: String, val members: List<BandMemberReadDTO>) : IReadDTO

/**
 * Data transfer object used to change band name
 * @property name new name of band being changed
 */
data class BandUpdateDTO (val name: String?) : IUpdateDTO

/**
 * Data transfer object used for creating new band
 * @property name name of newly created band
 */
data class BandCreateDTO (val name: String) : ICreateDTO
