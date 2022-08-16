from brownie import Blast , config , network , accounts
from scripts.helpful_scripts import get_account , fund_with_link , get_contract
import time
from web3 import Web3
def deploy_blast():
    account = get_account()
    blast = Blast.deploy(
                get_contract("eth_usd_price_feed").address,
                get_contract('vrf_coordinator').address,
                get_contract('link_token').address,
                config["networks"][network.show_active()]["keyhash"],
                config["networks"][network.show_active()]["fee"],
                {'from': account},
                publish_source=config["networks"][network.show_active()].get("verify", False))
    print('Blast deployed!!!')


def start_blast():
    account = get_account()
    blast = Blast[-1]
    start_tx = blast.start({"from": account})
    start_tx.wait(1)
    print("Blast started!!!")

def enter_blast():
    account = get_account()
    blast = Blast[-1]
    value = blast.entranceFee() + 100000000
    enter_tx = blast.enter(120 , {"from":account , "value": value})
    enter_tx.wait(1)
    print("you enter Blast!!!")

def finish_blast():
    account = get_account()
    blast = Blast[-1]
    fund_link_tx = fund_with_link(blast.address)
    fund_link_tx.wait(1)
    finish_tx = blast.finish({"from":account})
    finish_tx.wait(1)
    time.sleep(200)
    print(f"the random number is {blast.randomness()}")
    print(blast.players(0))
    
def charge_blast():
    account = get_account()
    blast = Blast[-1]
    value = 6000000000000000
    charge_tx = blast.charge({"from": account , "value": value})
    charge_tx.wait(1)
    print(f"account charged for {Web3.fromWei(value, 'ether')}")

def payment():
    account = get_account()
    blast = Blast[-1]
    randRatio_tx = blast.getRatio({"from": account})
    randRatio_tx.wait(1)
    print(f"the random ratio is {blast.randomRatio() / 100}")
    payment_tx = blast.blastPayment(
        {"from": account})
    payment_tx.wait(1)
    #"priority_fee": 3500000000
    print(f"we had {blast.winnerCounter()} winner!!!")



def main():
    deploy_blast()
    start_blast()
    charge_blast()
    enter_blast()
    finish_blast()
    payment()