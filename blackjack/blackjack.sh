# ============================================================
# Program: Blackjack (Whiptail Edition)
# Description:
#   Runs a text-based Blackjack game using Whiptail dialogs.
#   The player and dealer draw from a standard 52-card deck;
#   the script checks natural Blackjack, busts, and Five Card
#   Charlie, compares hands, updates the player's score, and
#   allows additional rounds until the player exits.
# Requirements: Bash and whiptail.
# ============================================================

# ============================================================
# Global Variables: scoring settings, score state, and dialog sizes
# ============================================================

BASE_POINTS=10
BLACKJACK_BONUS=5
CHARLIE_BONUS=20

playerScore=0
scoreMessage=""

# Whiptail dialog dimensions
DLG_HEIGHT=20
DLG_WIDTH=60
MSG_HEIGHT=15
MSG_WIDTH=55


# ============================================================
# Global Arrays: full deck, remaining deck, and each hand
# ============================================================

declare -a deck=(
    "A,A" "2,A" "3,A" "4,A" "5,A" "6,A" "7,A" "8,A" "9,A" "10,A" "J,A" "Q,A" "K,A"
    "A,H" "2,H" "3,H" "4,H" "5,H" "6,H" "7,H" "8,H" "9,H" "10,H" "J,H" "Q,H" "K,H"
    "A,S" "2,S" "3,S" "4,S" "5,S" "6,S" "7,S" "8,S" "9,S" "10,S" "J,S" "Q,S" "K,S"
    "A,C" "2,C" "3,C" "4,C" "5,C" "6,C" "7,C" "8,C" "9,C" "10,C" "J,C" "Q,C" "K,C"
)

declare -a tempDeck
declare -a playerHand
declare -a dealerHand


# ============================================================
# Functions: dialog helpers and hand formatting
# ============================================================

# Display a message in a modal Whiptail dialog.
showMessage() {
    local title="$1"
    local message="$2"
    whiptail --title "$title" --msgbox "$message" $MSG_HEIGHT $MSG_WIDTH
}

# Display a temporary information message.
showInfo() {
    local title="$1"
    local message="$2"
    whiptail --title "$title" --infobox "$message" $MSG_HEIGHT $MSG_WIDTH
    sleep 1.5
}

# Ask a yes/no question; the Whiptail exit status indicates the answer.
askYesNo() {
    local title="$1"
    local message="$2"
    whiptail --title "$title" --yesno "$message" $MSG_HEIGHT $MSG_WIDTH
}

# Format a list of cards as a readable hand string.
formatHand() {
    local -a hand=("$@")
    local result=""
    for card in "${hand[@]}"; do
        result+="[${card}] "
    done
    echo "$result"
}


# ============================================================
# Function: deal a card
# ============================================================

# Select a random card from tempDeck, remove it, and return it.
dealCard()
{
    local drawnCardIndex
    local drawnCard

    # Choose a random index, remove that card, then re-pack the array
    # so later random selections use only cards still in the deck.
    drawnCardIndex=$((RANDOM % ${#tempDeck[@]}))

    drawnCard="${tempDeck[$drawnCardIndex]}"

    unset 'tempDeck[drawnCardIndex]'
    tempDeck=("${tempDeck[@]}")

    echo "$drawnCard"
}


# ============================================================
# Function: calculate an individual card value
# ============================================================

# Return a card value, choosing Ace as 11 only when it does not exceed 21.
getCardPoint()
{
    local card="$1"
    local currentPoint="$2"

    local rank
    local suit
    local point=0

    # Split the stored "rank,suit" representation; only rank affects points.
    IFS=',' read -r rank suit <<< "$card"

    case "$rank" in

        A)
            if (( currentPoint + 11 <= 21 ))
            then
                point=11
            else
                point=1
            fi
            ;;

        2) point=2 ;;
        3) point=3 ;;
        4) point=4 ;;
        5) point=5 ;;
        6) point=6 ;;
        7) point=7 ;;
        8) point=8 ;;
        9) point=9 ;;
        10|J|Q|K) point=10 ;;

    esac

    echo "$point"
}


# ============================================================
# Function: calculate a hand total
# ============================================================

# Sum the values of all supplied cards, adjusting Aces as the total grows.
calculateHandTotal()
{
    local total=0
    local card
    local point

    # Pass the running total when valuing each card so an Ace can be 1 or 11.
    for card in "$@"
    do
        point=$(getCardPoint "$card" "$total")
        (( total += point ))
    done

    echo "$total"
}


# ============================================================
# Function: check for natural Blackjack
# ============================================================

# Return true for a two-card Ace plus 10-value-card Blackjack.
blackJackCheck()
{
    local firstCard="$1"
    local secondCard="$2"

    local rankFst
    local suitFst
    local rankSnd
    local suitSnd

    IFS=',' read -r rankFst suitFst <<< "$firstCard"
    IFS=',' read -r rankSnd suitSnd <<< "$secondCard"

    if [[ "$rankFst" == "A" && "$rankSnd" =~ ^(10|J|Q|K)$ ]]
    then
        echo "true"
    elif [[ "$rankSnd" == "A" && "$rankFst" =~ ^(10|J|Q|K)$ ]]
    then
        echo "true"
    else
        echo "false"
    fi
}


# ============================================================
# Function: resolve immediate Blackjack outcomes
# ============================================================

# Resolve initial natural Blackjacks as player, dealer, push, or continue.
blackJackOutcome()
{
    local dealerBlackJack="$1"
    local playerBlackJack="$2"

    if [[ "$dealerBlackJack" == "true" && "$playerBlackJack" == "true" ]]
    then
        echo "push"
    elif [[ "$dealerBlackJack" == "true" && "$playerBlackJack" == "false" ]]
    then
        echo "dealer"
    elif [[ "$dealerBlackJack" == "false" && "$playerBlackJack" == "true" ]]
    then
        echo "player"
    else
        echo "continue"
    fi
}


# ============================================================
# Function: compare hand totals
# ============================================================

# Compare final hand totals and return player, dealer, or push.
comparePoints()
{
    local playerPoint="$1"
    local dealerPoint="$2"

    if (( playerPoint > 21 ))
    then
        echo "dealer"
    elif (( dealerPoint > 21 ))
    then
        echo "player"
    elif (( playerPoint > dealerPoint ))
    then
        echo "player"
    elif (( playerPoint < dealerPoint ))
    then
        echo "dealer"
    else
        echo "push"
    fi
}


# ============================================================
# Function: update the player's score
# ============================================================
# NOTE: This function MUTATES the global playerScore and sets
# the global scoreMessage. It MUST be called directly (not via
# command substitution) so the changes persist in the parent
# shell. The caller reads $scoreMessage afterwards.

# Update global playerScore and scoreMessage for the supplied outcome.
updateScore()
{
    local outcome="$1"

    scoreMessage=""

    case "$outcome" in

        win)
            (( playerScore += BASE_POINTS ))
            scoreMessage="You gained $BASE_POINTS points."
            ;;

        blackjack)
            (( playerScore += BASE_POINTS + BLACKJACK_BONUS ))
            scoreMessage="Blackjack bonus: +$BLACKJACK_BONUS points.\nYou gained $((BASE_POINTS + BLACKJACK_BONUS)) points."
            ;;

        charlie)
            (( playerScore += BASE_POINTS + CHARLIE_BONUS ))
            scoreMessage="Five Card Charlie bonus: +$CHARLIE_BONUS points.\nYou gained $((BASE_POINTS + CHARLIE_BONUS)) points."
            ;;

        loss)
            (( playerScore -= BASE_POINTS ))
            scoreMessage="You lost $BASE_POINTS points."
            ;;

        push)
            scoreMessage="Push - no points gained or lost."
            ;;

    esac
}


# ============================================================
# Function: check the Five Card Charlie condition
# ============================================================

# Return success when the player has five cards totaling 21 or less.
checkCharlie()
{
    local handSize="$1"
    local handPoint="$2"

    if (( handSize == 5 && handPoint <= 21 ))
    then
        return 0
    else
        return 1
    fi
}


# ============================================================
# Function: build the game-state display text
# ============================================================

# Build a formatted summary of the score, deck, hands, and optional message.
buildGameState()
{
    local showDealer="$1"
    local playerPoint="$2"
    local dealerPoint="$3"
    local extraInfo="$4"

    local state=""
    state+="Current Points: $playerScore\n"
    state+="Cards remaining: ${#tempDeck[@]}\n"
    state+="\n"
    state+="--- Dealer ---\n"

    if [[ "$showDealer" == "full" ]]
    then
        state+="$(formatHand "${dealerHand[@]}")\n"
        state+="Total: $dealerPoint\n"
    else
        state+="[Hidden] $(formatHand "${dealerHand[1]}")\n"
    fi

    state+="\n"
    state+="--- Player ---\n"
    state+="$(formatHand "${playerHand[@]}")\n"

    if [[ -n "$playerPoint" ]]
    then
        state+="Total: $playerPoint\n"
    fi

    if [[ -n "$extraInfo" ]]
    then
        state+="\n$extraInfo"
    fi

    echo "$state"
}


# ============================================================
# Main Program: play rounds, resolve outcomes, and handle replay
# ============================================================

gameloop="true"

whiptail --title "BLACKJACK" --msgbox "Welcome to Blackjack!\n\nPress OK to start playing." 12 50

while [[ "$gameloop" == "true" ]]
do

    # ========================================================
    # Reset Deck and Hands
    # Each round starts with a fresh copy of the full deck and empty hands.
    # ========================================================

    tempDeck=("${deck[@]}")
    playerHand=()
    dealerHand=()


    # ========================================================
    # Initial Deal
    # ========================================================

    dealerHand+=("$(dealCard)")
    dealerHand+=("$(dealCard)")

    playerHand+=("$(dealCard)")
    playerHand+=("$(dealCard)")


    # ========================================================
    # Blackjack Check
    # Resolve natural Blackjack before allowing the player to hit or stand.
    # ========================================================

    dealerBlackJack=$(blackJackCheck "${dealerHand[0]}" "${dealerHand[1]}")
    playerBlackJack=$(blackJackCheck "${playerHand[0]}" "${playerHand[1]}")

    outcome=$(blackJackOutcome "$dealerBlackJack" "$playerBlackJack")


    # ========================================================
    # Immediate Blackjack Outcomes
    # ========================================================

    if [[ "$outcome" == "dealer" ]]
    then

        msg="DEALER BLACKJACK!\n\n"
        msg+="Dealer: $(formatHand "${dealerHand[@]}")\n"
        msg+="Player: $(formatHand "${playerHand[@]}")\n\n"
        msg+="Dealer has Blackjack!\nPlayer loses."

        showMessage "Dealer Blackjack" "$msg"

        updateScore "loss"
        showMessage "Round Result" "$scoreMessage\n\nPlayer points: $playerScore"


    elif [[ "$outcome" == "player" ]]
    then

        msg="NATURAL BLACKJACK!\n\n"
        msg+="Dealer: $(formatHand "${dealerHand[@]}")\n"
        msg+="Player: $(formatHand "${playerHand[@]}")\n\n"
        msg+="Player has Blackjack!\nPlayer wins!"

        showMessage "Blackjack!" "$msg"

        updateScore "blackjack"
        showMessage "Round Result" "$scoreMessage\n\nPlayer points: $playerScore"


    elif [[ "$outcome" == "push" ]]
    then

        msg="PUSH!\n\n"
        msg+="Dealer: $(formatHand "${dealerHand[@]}")\n"
        msg+="Player: $(formatHand "${playerHand[@]}")\n\n"
        msg+="Both player and dealer have Blackjack."

        showMessage "Push" "$msg"

        updateScore "push"
        showMessage "Round Result" "$scoreMessage\n\nPlayer points: $playerScore"


    else

        # ====================================================
        # PLAYER TURN
        # ====================================================

        stand="false"
        charlie="false"
        busted="false"

        while [[ "$stand" == "false" ]]
        do

            playerPoint=$(calculateHandTotal "${playerHand[@]}")

            # ------------------------------------------------
            # Player Bust
            # ------------------------------------------------

            if (( playerPoint > 21 ))
            then
                msg="PLAYER BUSTS!\n\n"
                msg+="Player hand: $(formatHand "${playerHand[@]}")\n"
                msg+="Player total: $playerPoint\n\n"
                msg+="Dealer wins."

                showMessage "Bust!" "$msg"

                busted="true"
                break
            fi


            # ------------------------------------------------
            # Five Card Charlie
            # ------------------------------------------------

            if checkCharlie "${#playerHand[@]}" "$playerPoint"
            then
                msg="FIVE CARD CHARLIE!\n\n"
                msg+="Player hand: $(formatHand "${playerHand[@]}")\n"
                msg+="Player total: $playerPoint\n\n"
                msg+="Player reached five cards without busting.\n"
                msg+="Player automatically wins!"

                showMessage "Five Card Charlie!" "$msg"

                charlie="true"
                stand="true"
                break
            fi


            # ------------------------------------------------
            # Player Choice
            # ------------------------------------------------

            dealerDisplay="[Hidden] ${dealerHand[1]}"

            choice=$(whiptail --title "Player Turn" \
                --menu "Player hand: $(formatHand "${playerHand[@]}")\nPlayer total: $playerPoint\nCurrent points: $playerScore\n\nDealer: $dealerDisplay\n\nWhat would you like to do?" \
                $DLG_HEIGHT $DLG_WIDTH 2 \
                "Hit" "Draw another card" \
                "Stand" "Keep your current hand" \
                3>&1 1>&2 2>&3)

            # Treat Esc/Cancel as Stand so the round can continue safely.
            if [[ $? -ne 0 ]]
            then
                choice="Stand"
            fi

            case "$choice" in

                "Stand")
                    stand="true"
                    ;;

                "Hit")
                    playerHand+=("$(dealCard)")

                    newCard="${playerHand[-1]}"
                    newTotal=$(calculateHandTotal "${playerHand[@]}")

                    showInfo "Card Dealt" "You drew: $newCard\n\nPlayer hand: $(formatHand "${playerHand[@]}")\nPlayer total: $newTotal"

                    ;;

            esac

        done


        # ====================================================
        # Five Card Charlie Outcome
        # ====================================================

        if [[ "$charlie" == "true" ]]
        then

            updateScore "charlie"
            showMessage "Round Result" "$scoreMessage\n\nPlayer points: $playerScore"


        elif [[ "$busted" == "true" ]]
        then

            updateScore "loss"
            showMessage "Round Result" "$scoreMessage\n\nPlayer points: $playerScore"


        else

            # =================================================
            # Calculate Player Total After Player Turn
            # =================================================

            playerPoint=$(calculateHandTotal "${playerHand[@]}")


            # =============================================
            # DEALER TURN
            # =============================================

            dealerPoint=$(calculateHandTotal "${dealerHand[@]}")

            dealerMsg="DEALER TURN\n\n"
            dealerMsg+="Dealer reveals: $(formatHand "${dealerHand[@]}")\n"
            dealerMsg+="Dealer total: $dealerPoint"

            showMessage "Dealer Turn" "$dealerMsg"


            # =============================================
            # Dealer Hits Until 17
            # The dealer draws repeatedly while the total is below 17.
            # =============================================

            while (( dealerPoint < 17 ))
            do

                dealerHand+=("$(dealCard)")
                dealerPoint=$(calculateHandTotal "${dealerHand[@]}")

                hitMsg="Dealer hits.\n\n"
                hitMsg+="Dealer drew: ${dealerHand[-1]}\n"
                hitMsg+="Dealer hand: $(formatHand "${dealerHand[@]}")\n"
                hitMsg+="Dealer total: $dealerPoint"

                showMessage "Dealer Hits" "$hitMsg"

            done


            # =============================================
            # Dealer Bust
            # =============================================

            if (( dealerPoint > 21 ))
            then

                msg="DEALER BUSTS!\n\n"
                msg+="Player hand: $(formatHand "${playerHand[@]}")\n"
                msg+="Player total: $playerPoint\n\n"
                msg+="Dealer hand: $(formatHand "${dealerHand[@]}")\n"
                msg+="Dealer total: $dealerPoint\n\n"
                msg+="Player wins!"

                showMessage "Dealer Bust!" "$msg"

                updateScore "win"
                showMessage "Round Result" "$scoreMessage\n\nPlayer points: $playerScore"


            else

                # =========================================
                # Final Comparison
            # Only compare totals here if the dealer has not busted.
                # =========================================

                finalMsg="FINAL RESULT\n\n"
                finalMsg+="Player hand: $(formatHand "${playerHand[@]}")\n"
                finalMsg+="Player total: $playerPoint\n\n"
                finalMsg+="Dealer hand: $(formatHand "${dealerHand[@]}")\n"
                finalMsg+="Dealer total: $dealerPoint\n\n"

                outcome=$(comparePoints "$playerPoint" "$dealerPoint")

                case "$outcome" in

                    player)
                        finalMsg+="PLAYER WINS!"
                        showMessage "Final Result" "$finalMsg"
                        updateScore "win"
                        ;;

                    dealer)
                        finalMsg+="DEALER WINS."
                        showMessage "Final Result" "$finalMsg"
                        updateScore "loss"
                        ;;

                    push)
                        finalMsg+="PUSH - both hands have the same value."
                        showMessage "Final Result" "$finalMsg"
                        updateScore "push"
                        ;;

                esac

                showMessage "Round Result" "$scoreMessage\n\nPlayer points: $playerScore"

            fi

        fi

    fi


    # ========================================================
    # Continue Game
    # ========================================================

    if ! askYesNo "Play Again?" "Player points: $playerScore\n\nPlay another round?"
    then
        gameloop="false"
    fi

done


# ============================================================
# Final Score
# Display the accumulated score and classify it as positive, negative, or even.
# ============================================================

finalMsg="GAME OVER\n\n"
finalMsg+="Final Player Score: $playerScore points\n\n"

if (( playerScore > 0 ))
then
    finalMsg+="Overall result: Positive score."
elif (( playerScore < 0 ))
then
    finalMsg+="Overall result: Negative score."
else
    finalMsg+="Overall result: Even score."
fi

finalMsg+="\n\nThanks for playing Blackjack!"

whiptail --title "Game Over" --msgbox "$finalMsg" 14 50

clear