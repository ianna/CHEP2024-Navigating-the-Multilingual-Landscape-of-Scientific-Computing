module DummyAwkwardModule

export invariant_mass

using LorentzVectorHEP, AwkwardArray
using UnROOT

using Base.Threads

function invariant_mass(cms_events)

    array = AwkwardArray.PrimitiveArray{Float64}()
    lock_obj = ReentrantLock()  # Create a lock object to control access to shared array

    @threads for i in 1:length(cms_events)
        evt = cms_events[i]

        # Destructure the necessary fields from the event
        (; Muon_charge, Muon_pt, Muon_eta, Muon_phi, Muon_mass, nMuon) = evt

        # Skip event if it doesn't meet the required conditions
        if nMuon != 2 || Muon_charge[1] == Muon_charge[2]
            continue
        end

        # Calculate invariant mass using LorentzVectorHEP for clarity and accuracy
        muon1 = LorentzVectorCyl(Muon_pt[1], Muon_eta[1], Muon_phi[1], Muon_mass[1])
        muon2 = LorentzVectorCyl(Muon_pt[2], Muon_eta[2], Muon_phi[2], Muon_mass[2])
        result = mass(muon1 + muon2)
                
        # Only add masses greater than 70 GeV
        if result > 70
            # Use lock to safely push! into the shared array
            lock(lock_obj)  # Explicitly lock before modifying shared data
            try
                push!(array, result)
            finally
                unlock(lock_obj)  # Ensure the lock is always released
            end
        end
    end
    
    return array
end

end