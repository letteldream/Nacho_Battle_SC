import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { parseUnits } from 'ethers/lib/utils'
import { deployments, ethers, network } from 'hardhat'
import { MaticWETH, Tomb, TBond, Luchador, Trainer, Battle } from '../typechain'

describe('Battle Game', () => {
  let deployer: SignerWithAddress,
    register1: SignerWithAddress,
    register2: SignerWithAddress,
    spectator1: SignerWithAddress,
    spectator2: SignerWithAddress,
    multisig: SignerWithAddress
  let weth: MaticWETH
  let nacho: Tomb
  let nbond: TBond
  let luchador: Luchador
  // let trainer: Trainer
  let battle: Battle

  before(async () => {
    ;[deployer, register1, register2, spectator1, spectator2, multisig] = await ethers.getSigners()

    await deployments.fixture('SetRegistry')

    let receipt = await deployments.deploy('MaticWETH', {
      from: deployer.address,
      args: [],
      log: true,
    })
    weth = await ethers.getContractAt('Tomb', receipt.address)
    receipt = await deployments.deploy('Tomb', {
      from: deployer.address,
      args: [100, deployer.address],
      log: true,
    })
    nacho = await ethers.getContractAt('Tomb', receipt.address)
    receipt = await deployments.deploy('TBond', {
      from: deployer.address,
      args: [],
      log: true,
    })
    nbond = await ethers.getContractAt('TBond', receipt.address)
    receipt = await deployments.deploy('Luchador', {
      from: deployer.address,
      args: [nacho.address, nbond.address, weth.address, multisig.address],
      log: true,
    })
    luchador = await ethers.getContractAt('Luchador', receipt.address)
    receipt = await deployments.deploy('Battle', {
      from: deployer.address,
      args: [nacho.address, nbond.address, luchador.address],
      log: true,
    })
    battle = await ethers.getContractAt('Battle', receipt.address)
  })
  describe('Deploy contract', async () => {
    it('should be deployed', async () => {})
  })

  describe('Initialize', () => {
    it('Mint Nacho & Nbond', async () => {
      await nacho.mint(register1.address, ethers.utils.parseEther('1000000'))
      await nacho.mint(register2.address, ethers.utils.parseEther('1000000'))
      await nacho.mint(spectator1.address, ethers.utils.parseEther('1000000'))
      await nacho.mint(spectator2.address, ethers.utils.parseEther('1000000'))

      await nbond.mint(battle.address, ethers.utils.parseEther('1000000'))

      await weth.transfer(register1.address, ethers.utils.parseEther('1000000'))
      await weth.transfer(register2.address, ethers.utils.parseEther('1000000'))
    })
    it('Mint Luchador NFT', async () => {
      await luchador.addTokenURI('1')
      await luchador.addTokenURI('2')
      await luchador.addTokenURI('3')
      await luchador.addTokenURI('4')
      await luchador.addTokenURI('5')
      await luchador.addTokenURI('6')
      await luchador.addTokenURI('7')
      await luchador.addTokenURI('8')
      await luchador.addTokenURI('9')
      await luchador.addTokenURI('10')
      await luchador.addTokenURI('11')
      await luchador.addTokenURI('12')

      await weth.connect(register1).approve(luchador.address, ethers.utils.parseEther('400'))
      await weth.connect(register2).approve(luchador.address, ethers.utils.parseEther('400'))
      await luchador.connect(register1).mint(6)
      await luchador.connect(register2).mint(6)
    })
    it('Feed NFT to increase weight', async () => {
      for (let i = 0; i < 6; i++) {
        await nacho.connect(register1).approve(luchador.address, ethers.utils.parseEther('100000'))
        await nacho.connect(register2).approve(luchador.address, ethers.utils.parseEther('100000'))
        await luchador.connect(register1).feedNacho(i + 1, i * 10 + 67)
        await luchador.connect(register2).feedNacho(i + 7, i * 10 + 60)
      }
      expect(await luchador.luchadoresWeight(1)).to.equal(67)
    })
    it('Prepare game', async () => {
      await battle.setBattleStartTime(Math.floor(Date.now() / 1000))
    })
  })

  describe('Battle', () => {
    it('Register Battle', async () => {
      for (let i = 0; i < 6; i++) {
        await nacho.connect(register1).approve(battle.address, ethers.utils.parseEther('100000'))
        await nacho.connect(register2).approve(battle.address, ethers.utils.parseEther('100000'))
        await battle.connect(register1).registerVersusBattle(i, i + 1)
        await battle.connect(register2).registerVersusBattle(i, i + 7)
        let versusFighters = await battle.versusFighters(2, 0)
        console.log('versusFighters1', versusFighters)
        versusFighters = await battle.versusFighters(2, 1)
        console.log('versusFighters2', versusFighters)
        // expect(await battle.versusFighters(2, 1)).to.equal(9)
      }
    })
    it('Fight Versus Battle', async () => {
      await battle.fightVersusBattle()
      let versusRoomResult = await battle.versusRoomResult(0)
      console.log('versusRoomResult1', versusRoomResult)
      versusRoomResult = await battle.versusRoomResult(1)
      console.log('versusRoomResult2', versusRoomResult)
      versusRoomResult = await battle.versusRoomResult(2)
      console.log('versusRoomResult3', versusRoomResult)
      versusRoomResult = await battle.versusRoomResult(3)
      console.log('versusRoomResult4', versusRoomResult)
      versusRoomResult = await battle.versusRoomResult(4)
      console.log('versusRoomResult5', versusRoomResult)
      versusRoomResult = await battle.versusRoomResult(5)
      console.log('versusRoomResult6', versusRoomResult)

      let versusRoomRoundResult = await battle.versusRoomRoundResult(0, 0)
      console.log('versusRoomRoundResult1', versusRoomRoundResult)
      versusRoomRoundResult = await battle.versusRoomRoundResult(0, 1)
      console.log('versusRoomRoundResult2', versusRoomRoundResult)
      versusRoomRoundResult = await battle.versusRoomRoundResult(0, 2)
      console.log('versusRoomRoundResult3', versusRoomRoundResult)
      versusRoomRoundResult = await battle.versusRoomRoundResult(0, 3)
      console.log('versusRoomRoundResult4', versusRoomRoundResult)
      versusRoomRoundResult = await battle.versusRoomRoundResult(0, 4)
      console.log('versusRoomRoundResult5', versusRoomRoundResult)
      versusRoomRoundResult = await battle.versusRoomRoundResult(0, 5)
      console.log('versusRoomRoundResult6', versusRoomRoundResult)
      versusRoomRoundResult = await battle.versusRoomRoundResult(0, 6)
      console.log('versusRoomRoundResult7', versusRoomRoundResult)
    })
    // it('Success: depositFor', async () => {
    //   await airUSD.approve(stablePool.address, parseUnits('1'))
    //   await stablePool.depositFor(parseUnits('1'), anotherUser.address)

    //   expect(await stablePool.balanceOf(anotherUser.address)).to.equal(
    //     parseUnits('1'),
    //   )

    //   await airUSD.approve(stablePool.address, parseUnits('1'))
    //   await stablePool.depositFor(parseUnits('1'), anotherUser.address)

    //   expect(await stablePool.balanceOf(anotherUser.address)).to.equal(
    //     parseUnits('2'),
    //   )
    // })
  })
})
