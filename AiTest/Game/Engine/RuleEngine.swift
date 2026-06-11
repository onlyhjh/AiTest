//
//  RuleEngine.swift
//  AiGoStop iOS
//
//  Created by Joey's Mac mini on 5/6/26.
//

class RuleEngine {
    
    // 가능한 액션 생성
    func generateActions(state: GameState) -> [Action] {
        var actions: [Action] = []
        
        for handCard in state.currentPlayer.handCards {
            let matches = state.table.filter { $0.month == handCard.month }
            
            if matches.isEmpty {
                actions.append(Action(handCard: handCard, targetCard: nil))
            } else {
                for match in matches {
                    actions.append(Action(handCard: handCard, targetCard: match))
                }
            }
        }
        
        return actions
    }
    

    func simulate(state: GameState, action: Action) -> GameState {
        let newState = state
        
        newState.players[newState.currentPlayerIndex].handCards.removeAll { $0 == action.handCard }
        
        newState.table.append(action.handCard)
        
        return newState
    }
}


