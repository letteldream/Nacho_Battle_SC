import { ethers } from 'hardhat'
import { tombAddress, tbondAddress, luchardorAddress } from './address'

async function main(): Promise<string> {
  const [deployer] = await ethers.getSigners()
  if (deployer === undefined) throw new Error('Deployer is undefined.')

  console.log('Account balance:', (await deployer.getBalance()).toString())

  const Battle = await ethers.getContractFactory('Battle')
  const Battle_Deployed = await Battle.deploy(
    tombAddress,
    tbondAddress,
    luchardorAddress,
    '0x6168499c0cFfCaCD319c818142124B7A15E857ab',
    '0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc',
    9381,
  )

  return Battle_Deployed.address
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
