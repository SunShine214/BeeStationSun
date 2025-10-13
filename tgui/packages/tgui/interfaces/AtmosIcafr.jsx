import { useBackend } from '../backend';
import { Section } from '../components';
import { Window } from '../layouts';

export const AtmosIcafr = (props) => {
  const { act, data } = useBackend();
  const {
    reaction_energy,
    display_power,
    reaction_harvesting,
    reaction_harvesting_efficiency,
    display_parabolic_production,
  } = data;
  return (
    <Window theme="ntos" width={480} height={500}>
      <Window.Content>
        <Section title="ICAFR:" fill={1} overflow-y="scroll">
          Reaction Energy
          <br />
          {reaction_energy}
          <br />
          Output Power
          <br />
          {display_power}
          <br />
          Reaction Harvesting
          <br />
          {reaction_harvesting}
          <br />
          Reaction Harvesting Efficiency
          <br />
          {reaction_harvesting_efficiency}
          <br />
          Parabolic Production
          <br />
          {display_parabolic_production}
          <br />
        </Section>
      </Window.Content>
    </Window>
  );
};
