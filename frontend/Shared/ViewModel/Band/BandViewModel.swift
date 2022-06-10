//
//  BandViewModel.swift
//  ViewModel
//
//  Created by Ondřej Wrzecionko on 01.04.2022.
//

import SwiftUI

final class BandViewModel: ObservableObject {
    
    // MARK: - Published properties
    
    @Published var editMode: Bool = false
    @Published var band: Binding<Band>
    
    @Published var isCreateMemberDisplayed: Bool = false
    @Published var memberName: String = ""
    @Published var memberEmail: String = ""
    @Published var memberRole: RoleLevel = .MUSICIAN
    
    @Published var loading: Bool = false
    @Published var isBandMemberAlertDisplayed: Bool = false
    @Published var bandMemberAlertText: String = "" {
        didSet {
            isBandMemberAlertDisplayed = !bandMemberAlertText.isEmpty
        }
    }
    
    // MARK: - Private properties
    
    private let appState: AppState
    private let bandMemberService: BandMemberServicing
    
    // MARK: - Init
    
    init(band: Binding<Band>, context: HasAppState & HasBandMemberService) {
        self.band = band
        appState = context.appState
        bandMemberService = context.bandMemberService
    }
    
    // MARK: - Public methods
        
    /// Simple function to check for validity
    func isValid() -> Bool {
        !memberName.isEmpty && !memberEmail.isEmpty
    }
    
    func create() {
        if !isValid() {
            return
        }
        
        loading = true
        Task { await create() }
    }
    func create() async {
        let dto = BandMemberCreateDTO(email: memberEmail, name: memberName, roleId: memberRole.id)
        let result = await bandMemberService.create(bandId: band.wrappedValue.id, member: dto)
        await create(result: result)
    }
    
    func change(member: BandMember, role: RoleLevel) {
        loading = true
        Task { await change(member: member, role: role) }
    }
    func change(member: BandMember, role: RoleLevel) async {
        let result = await bandMemberService.change(
            bandId: band.wrappedValue.id,
            memberId: member.id,
            role: role
        )
        await change(member: member, role: role, result: result)
    }
    
    func delete(member: BandMember) {
        loading = true
        Task { await delete(member: member) }
    }
    func delete(member: BandMember) async {
        let result = await bandMemberService.delete(
            bandId: band.wrappedValue.id,
            memberId: member.id
        )
        await delete(member: member, result: result)
    }
    
    // MARK: - Private methods
    
    @MainActor
    private func create(result: Result<BandMemberDTO, HttpStatusError>) async {
        switch result {
        case .success(let bandMember):
            band.wrappedValue.members.append(bandMember.domain)
            bandMemberAlertText = NSLocalizedString("band_member_create_success", comment: "")
        case .failure(let error):
            bandMemberAlertText = NSLocalizedString("band_member_create_failure", comment: "") + error.errorDescription
        }
        
        // Clear data
        memberName = ""
        memberEmail = ""
        memberRole = .MUSICIAN
    }
    
    @MainActor
    private func change(member: BandMember, role: RoleLevel, result: Result<Void, HttpStatusError>) async {
        switch result {
        case .success(_):
            if let index = band.wrappedValue.members.firstIndex(where: { $0.id == member.id }) {
                band.wrappedValue.members[index].role = role
            }
            bandMemberAlertText = NSLocalizedString("band_member_change_role_success", comment: "")
        case .failure(let error):
            bandMemberAlertText = NSLocalizedString("band_member_change_role_failure", comment: "") + error.errorDescription
        }
    }
    
    @MainActor
    private func delete(member: BandMember, result: Result<Void, HttpStatusError>) async {
        switch result {
        case .success(_):
            // If deleted itself, logout user
            if member.userId == appState.user?.id {
                appState.logout()
                return
            }
            band.wrappedValue.members.removeAll(where: { $0.id == member.id })
            bandMemberAlertText = NSLocalizedString("band_member_delete_success", comment: "")
        case .failure(let error):
            bandMemberAlertText = NSLocalizedString("band_member_delete_failure", comment: "") + error.errorDescription
        }
    }
}
