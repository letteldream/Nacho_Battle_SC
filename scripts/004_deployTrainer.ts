import { ethers } from 'hardhat'
import { luchardorAddress } from './address'

async function main(): Promise<string> {
  const [deployer] = await ethers.getSigners()
  if (deployer === undefined) throw new Error('Deployer is undefined.')

  console.log('Account balance:', (await deployer.getBalance()).toString())

  const Trainer = await ethers.getContractFactory('Trainer')
  const Trainer_Deployed = await Trainer.deploy(luchardorAddress)

  return Trainer_Deployed.address
}

main()
  .then((r: string) => {
    console.log('deployed address:', r)
    return r
  })
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
